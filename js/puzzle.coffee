# borrowd from lodash.js:
# https://github.com/bestiejs/lodash/blob/master/lodash.js
_ =
  isArray: Array.isArray || (value) ->
    value instanceof Array || toString.call(value) == '[object Array]'

  flatten: (array, isShallow) ->
    index = -1
    length = if array then array.length else 0
    result = []
    if typeof isShallow is 'boolean' and isShallow is not null
      isShallow = false
    while ++index < length
      value = array[index]
      if _.isArray(value)
        result.push.apply(result, if isShallow then value else _.flatten(value))
      else
        result.push(value)
    result

window.Puzzle = class Puzzle
  strokeStyle: 'rgba(255, 0, 0, 0.25)'
  samenessThreshold: 0.05
  comparators:
    isMuchDarker: (v, min, upperMin) ->
      return false if min is false or upperMin is false
      if v >= min and v < upperMin then -2 else false
    isDarker: (v, upperMin, center) ->
      return false if upperMin is false
      if v >= upperMin and v < (center - 2) then -1 else false
    isSame: (v, center) ->
      if (center - 2) <= v and v <= (center + 2) then 0 else false
    isLighter: (v, center, lowerMax) ->
      return false if lowerMax is false
      if v > (center + 2) and v <= lowerMax then 1 else false
    isMuchLighter: (v, lowerMax, max) ->
      return false if max is false or lowerMax is false
      if v > lowerMax and v <= max then 2 else false

  getImageSignature: (img) ->
    canvas = @createCanvas img.width, img.height
    @drawImageOnCanvas canvas, img
    @computeVectorPoints canvas

  createCanvas: (w, h) ->
    c = document.getElementById 'canvas'
    if c is null
      c = document.createElement 'canvas'
      c.width = w
      c.height = h
      c.id = 'canvas'
      document.body.appendChild c
    c

  drawImageOnCanvas: (canvas, image) ->
    ctx = canvas.getContext('2d')
    ctx.drawImage image, 0, 0
    imgData = ctx.getImageData 0, 0, image.width, image.height
    for i in [0..imgData.data.length] by 4
      r = imgData.data[i]
      g = imgData.data[i+1]
      b = imgData.data[i+2]
      v = Math.floor(0.2126*r + 0.7152*g + 0.0722*b) # CIE luminance for RGB
      imgData.data[i] = imgData.data[i+1] = imgData.data[i+2] = v
    ctx.putImageData imgData, 0, 0

  computeVectorPoints: (canvas) ->
    width = canvas.width
    height = canvas.height
    imgData = canvas.getContext('2d').getImageData(0, 0, width, height)

    # crop away 5% of interestingness
    rows = @collatePixelRows imgData, width, height
    cols = @collatePixelColumns imgData, width, height
    rowsToCrop = @calcCrop rows, height, 'rows'
    colsToCrop = @calcCrop cols, width, 'cols'
    @cropRows canvas, rowsToCrop
    @cropCols canvas, colsToCrop

    handlePoints = @computeHandlePoints canvas

    @gridifyImage canvas, handlePoints # dev

    p = @computePValue canvas

    # NOTE unclear based on the outlined step three if I need to sample each
    # pixel as the average of a 3x3 grid centered on each pixel... seems kinda
    # excessive; electing to proceed without this for now, but should this
    # actually be necessary, this is the place to insert the logic

    handlePoints = @computeAverageGrayLevels canvas, handlePoints, p
    @addSampleSquaresToImage canvas, handlePoints, p

    vectorArray = @computeRelativeNeighborGrayLevels handlePoints
    console.log vectorArray

  computeRelativeNeighborGrayLevels: (handles) ->
    matrix = []
    i = 0
    matrix.push(handles.slice(i * 9, i * 9 + 9)) and i++ while i < 9
    vectorArray = []

    for rowIndex in [0..(matrix.length - 1)]
      for colIndex in [0..(matrix[rowIndex].length - 1)]
        neighbors = [
          matrix[(rowIndex - 1)]?[(colIndex - 1)]?.fill
          matrix[(rowIndex - 1)]?[colIndex]?.fill
          matrix[(rowIndex - 1)]?[(colIndex + 1)]?.fill
          matrix[rowIndex]?[(colIndex - 1)]?.fill
          matrix[rowIndex]?[(colIndex + 1)]?.fill
          matrix[(rowIndex + 1)]?[(colIndex - 1)]?.fill
          matrix[(rowIndex + 1)]?[colIndex]?.fill
          matrix[(rowIndex + 1)]?[(colIndex + 1)]?.fill
        ]

        center = matrix[rowIndex][colIndex].fill
        min = do -> Math.min.apply Math, neighbors.filter(Number)
        min = false if center < min
        max = do -> Math.max.apply Math, neighbors.filter(Number)
        max = false if center > lowerMax

        upperMin = do =>
          tolerance = Math.floor (center - min) * @samenessThreshold
          v = Math.floor (min + (center - tolerance)) / 2
          if center < v then false else v
        lowerMax = do =>
          tolerance = Math.floor (max - center) * @samenessThreshold
          v = Math.floor (max + (center + tolerance)) / 2
          if center > v then false else v

        rNeighbors = []
        for n in neighbors
          v = @comparators.isMuchDarker(n, min, upperMin)
          v = @comparators.isDarker(n, upperMin, center)    if v is false
          v = @comparators.isSame(n, center)                if v is false
          v = @comparators.isLighter(n, center, lowerMax)   if v is false
          v = @comparators.isMuchLighter(n, lowerMax, max)  if v is false
          v = 0                                             if v is false
          rNeighbors.push v
        vectorArray.push rNeighbors

    vectorArray

  computeAverageGrayLevels: (canvas, handles, p) ->
    ctx = canvas.getContext '2d'
    for point in handles
      imgData = ctx.getImageData (point.x - p/2), (point.y - p/2), p, p
      sum = 0
      total = 0
      for pixel in imgData.data by 4
        sum += pixel
        total++
      point.fill = Math.floor(sum / total)
    handles

  addSampleSquaresToImage: (canvas, handles, p) ->
    ctx = canvas.getContext '2d'
    cToHex = (c) ->
      hex = c.toString(16)
      if hex.length is 1 then '0' + hex else hex
    for point in handles
      c = "##{cToHex(point.fill)}#{cToHex(point.fill)}#{cToHex(point.fill)}"
      ctx.beginPath()
      ctx.rect (point.x - p/2), (point.y - p/2), p, p
      ctx.fillStyle = c
      ctx.fill()
      ctx.lineWidth = 2
      ctx.strokeStyle = @strokeStyle
      ctx.stroke()

  computePValue: (canvas) ->
    P = (m, n) -> Math.max(2, Math.floor(.5 + Math.min(n, m)/20))
    P canvas.width, canvas.height

  computeHandlePoints: (canvas) ->
    interval = 10
    xInt = Math.round canvas.width / interval
    yInt = Math.round canvas.height / interval
    xPaths = []
    yPaths = []
    for i in [0..(interval - 1)]
      unless i is 0
        xPaths.push Math.round(xInt * i)
        yPaths.push Math.round(yInt * i)
    handles = []
    for y in yPaths
      for x in xPaths
        handles.push { x: x, y: y }
    handles

  gridifyImage: (canvas, handles) ->
    xPaths = []
    yPaths = []
    for point in handles
      xPaths.push(point.x) if xPaths.indexOf(point.x) is -1
      yPaths.push(point.y) if yPaths.indexOf(point.y) is -1

    ctx = canvas.getContext '2d'

    for x in xPaths
      ctx.beginPath()
      ctx.moveTo x, 0
      ctx.lineTo x, canvas.height
      ctx.closePath()
      ctx.strokeStyle = @strokeStyle
      ctx.stroke()

    for y in yPaths
      ctx.beginPath()
      ctx.moveTo 0, y
      ctx.lineTo canvas.width, y
      ctx.closePath()
      ctx.strokeStyle = @strokeStyle
      ctx.stroke()

  collatePixelColumns: (imgData, width, height) ->
    d = imgData.data
    cols = new Array
    for x in [0..(width - 1)]
      diffs = new Array
      mx = x * 4 # starting pixel, top of each column
      nmx = mx + width * 4
      while d[nmx]?
        diffs.push Math.abs(d[mx] - d[nmx])
        mx = nmx
        nmx = nmx + width * 4
      cols.push diffs.reduce(((a,b) -> a + b), 0)
    cols

  collatePixelRows: (imgData, width, height) ->
    d = imgData.data
    rows = new Array
    for y in [0..(height - 1)]
      diffs = new Array
      col = 0
      my = y * width * 4 # starting pixel, start of each row
      nmy = my + 4
      while col < width and d[nmy]?
        diffs.push Math.abs(d[my] - d[nmy])
        my = nmy
        nmy = nmy + 4
        col++
      rows.push diffs.reduce(((a,b) -> a + b), 0)
    rows

  calcCrop: (array, dimension, dimensionType) ->
    total = array.reduce ((a,b) -> a + b), 0
    fivePercent = Math.round total * .05
    @pingPongCrop array, dimension, fivePercent, dimensionType

  pingPongCrop: (array, max, target, type) ->
    min = 0
    i = 0
    sum = 0
    beat = 'tick'
    firstCrop = []
    secondCrop = []
    while sum <= target
      if beat is 'tick'
        v = array[min + i]
        firstCrop.push min + i
        beat = 'tock'
      else
        v = array[(max - 1) - i]
        secondCrop.push max - i
        i++
        beat = 'tick'
      sum += v
    ret = {}
    if type is 'cols'
      ret.left = firstCrop.length
      ret.right = secondCrop.length
    else
      ret.top = firstCrop.length
      ret.bottom = secondCrop.length
    ret

  cropCols: (canvas, colsToCrop) ->
    ctx = canvas.getContext('2d')
    imgData = ctx.getImageData(0, 0, canvas.width, canvas.height)
    canvas.width = canvas.width - (colsToCrop.left + colsToCrop.right)
    ctx.putImageData imgData, -colsToCrop.left, 0

  cropRows: (canvas, rowsToCrop) ->
    ctx = canvas.getContext('2d')
    imgData = ctx.getImageData(0, 0, canvas.width, canvas.height)
    canvas.height = canvas.height - (rowsToCrop.top + rowsToCrop.bottom)
    ctx.putImageData imgData, 0, -rowsToCrop.top
