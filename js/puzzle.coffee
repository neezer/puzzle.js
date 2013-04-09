window.Puzzle = class Puzzle
  getImageSignature: (img) ->
    canvas = @createCanvas img.width, img.height
    @drawImageOnCanvas canvas, img
    @create9x9DifferenceGrid canvas

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

  create9x9DifferenceGrid: (canvas) ->
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

    @gridifyImage canvas

  gridifyImage: (canvas) ->
    interval = 10
    xInt = Math.round canvas.width / interval
    yInt = Math.round canvas.height / interval
    xPaths = []
    yPaths = []
    for i in [0..(interval - 1)]
      unless i is 0
        xPaths.push Math.round(xInt * i)
        yPaths.push Math.round(yInt * i)

    ctx = canvas.getContext '2d'

    for x in xPaths
      ctx.beginPath()
      ctx.moveTo x, 0
      ctx.lineTo x, canvas.height
      ctx.closePath()
      ctx.strokeStyle = '#f00'
      ctx.stroke()

    for y in yPaths
      ctx.beginPath()
      ctx.moveTo 0, y
      ctx.lineTo canvas.width, y
      ctx.closePath()
      ctx.strokeStyle = '#f00'
      ctx.stroke()

  collatePixelColumns: (imgData, width, height) ->
    d = imgData.data
    cols = new Array
    for x in [0..(width - 1)]
      mx = x * 4 # starting pixel, top of each column
      diffs = new Array
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

  calcCrop: (array, dimension, dimension_type) ->
    total = array.reduce ((a,b) -> a + b), 0
    fivePercent = Math.round total * .05
    @pingPongCrop array, dimension, fivePercent, dimension_type

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
