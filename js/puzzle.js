// Generated by CoffeeScript 1.3.3
(function() {
  var Puzzle;

  window.Puzzle = Puzzle = (function() {

    function Puzzle() {}

    Puzzle.prototype.getImageSignature = function(img) {
      var canvas;
      canvas = this.createCanvas(img.width, img.height);
      this.drawImageOnCanvas(canvas, img);
      return this.create9x9DifferenceGrid(canvas);
    };

    Puzzle.prototype.createCanvas = function(w, h) {
      var c;
      c = document.getElementById('canvas');
      if (c === null) {
        c = document.createElement('canvas');
        c.width = w;
        c.height = h;
        c.id = 'canvas';
        document.body.appendChild(c);
      }
      return c;
    };

    Puzzle.prototype.drawImageOnCanvas = function(canvas, image) {
      var b, ctx, g, i, imgData, r, v, _i, _ref;
      ctx = canvas.getContext('2d');
      ctx.drawImage(image, 0, 0);
      imgData = ctx.getImageData(0, 0, image.width, image.height);
      for (i = _i = 0, _ref = imgData.data.length; _i <= _ref; i = _i += 4) {
        r = imgData.data[i];
        g = imgData.data[i + 1];
        b = imgData.data[i + 2];
        v = Math.floor(0.2126 * r + 0.7152 * g + 0.0722 * b);
        imgData.data[i] = imgData.data[i + 1] = imgData.data[i + 2] = v;
      }
      return ctx.putImageData(imgData, 0, 0);
    };

    Puzzle.prototype.create9x9DifferenceGrid = function(canvas) {
      var averageGrayLevels, cols, colsToCrop, handlePoints, height, imgData, p, rows, rowsToCrop, width;
      width = canvas.width;
      height = canvas.height;
      imgData = canvas.getContext('2d').getImageData(0, 0, width, height);
      rows = this.collatePixelRows(imgData, width, height);
      cols = this.collatePixelColumns(imgData, width, height);
      rowsToCrop = this.calcCrop(rows, height, 'rows');
      colsToCrop = this.calcCrop(cols, width, 'cols');
      this.cropRows(canvas, rowsToCrop);
      this.cropCols(canvas, colsToCrop);
      handlePoints = this.computeHandlePoints(canvas);
      p = this.computePValue(canvas);
      averageGrayLevels = this.computeAverageGrayLevels(canvas, handlePoints, p);
      return this.addSampleSquaresToImage(canvas, averageGrayLevels, p);
    };

    Puzzle.prototype.computeAverageGrayLevels = function(canvas, handles, p) {
      var ctx, imgData, pixel, point, sum, total, _i, _j, _len, _len1, _ref, _step;
      ctx = canvas.getContext('2d');
      for (_i = 0, _len = handles.length; _i < _len; _i++) {
        point = handles[_i];
        imgData = ctx.getImageData(point.x - p / 2, point.y - p / 2, p, p);
        sum = 0;
        total = 0;
        _ref = imgData.data;
        for (_j = 0, _len1 = _ref.length, _step = 4; _j < _len1; _j += _step) {
          pixel = _ref[_j];
          sum += pixel;
          total++;
        }
        point.fill = sum / total;
      }
      return handles;
    };

    Puzzle.prototype.addSampleSquaresToImage = function(canvas, handles, p) {
      var c, cToHex, ctx, point, _i, _len, _results;
      ctx = canvas.getContext('2d');
      cToHex = function(c) {
        var hex;
        hex = Math.floor(c).toString(16);
        if (hex.length === 1) {
          return '0' + hex;
        } else {
          return hex;
        }
      };
      _results = [];
      for (_i = 0, _len = handles.length; _i < _len; _i++) {
        point = handles[_i];
        c = "#" + (cToHex(point.fill)) + (cToHex(point.fill)) + (cToHex(point.fill));
        ctx.beginPath();
        ctx.rect(point.x - p / 2, point.y - p / 2, p, p);
        ctx.fillStyle = c;
        ctx.fill();
        ctx.lineWidth = 2;
        ctx.strokeStyle = '#fff';
        _results.push(ctx.stroke());
      }
      return _results;
    };

    Puzzle.prototype.computePValue = function(canvas) {
      var P;
      P = function(m, n) {
        return Math.max(2, Math.floor(.5 + Math.min(n, m) / 20));
      };
      return P(canvas.width, canvas.height);
    };

    Puzzle.prototype.computeHandlePoints = function(canvas) {
      var handles, i, interval, x, xInt, xPaths, y, yInt, yPaths, _i, _j, _k, _len, _len1, _ref;
      interval = 10;
      xInt = Math.round(canvas.width / interval);
      yInt = Math.round(canvas.height / interval);
      xPaths = [];
      yPaths = [];
      for (i = _i = 0, _ref = interval - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (i !== 0) {
          xPaths.push(Math.round(xInt * i));
          yPaths.push(Math.round(yInt * i));
        }
      }
      handles = [];
      for (_j = 0, _len = yPaths.length; _j < _len; _j++) {
        y = yPaths[_j];
        for (_k = 0, _len1 = xPaths.length; _k < _len1; _k++) {
          x = xPaths[_k];
          handles.push({
            x: x,
            y: y
          });
        }
      }
      return handles;
    };

    Puzzle.prototype.gridifyImage = function(canvas, handles) {
      var ctx, point, x, xPaths, y, yPaths, _i, _j, _k, _len, _len1, _len2, _results;
      xPaths = [];
      yPaths = [];
      for (_i = 0, _len = handles.length; _i < _len; _i++) {
        point = handles[_i];
        if (xPaths.indexOf(point.x) === -1) {
          xPaths.push(point.x);
        }
        if (yPaths.indexOf(point.y) === -1) {
          yPaths.push(point.y);
        }
      }
      ctx = canvas.getContext('2d');
      for (_j = 0, _len1 = xPaths.length; _j < _len1; _j++) {
        x = xPaths[_j];
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvas.height);
        ctx.closePath();
        ctx.strokeStyle = '#f00';
        ctx.stroke();
      }
      _results = [];
      for (_k = 0, _len2 = yPaths.length; _k < _len2; _k++) {
        y = yPaths[_k];
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(canvas.width, y);
        ctx.closePath();
        ctx.strokeStyle = '#f00';
        _results.push(ctx.stroke());
      }
      return _results;
    };

    Puzzle.prototype.collatePixelColumns = function(imgData, width, height) {
      var cols, d, diffs, mx, nmx, x, _i, _ref;
      d = imgData.data;
      cols = new Array;
      for (x = _i = 0, _ref = width - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; x = 0 <= _ref ? ++_i : --_i) {
        mx = x * 4;
        diffs = new Array;
        nmx = mx + width * 4;
        while (d[nmx] != null) {
          diffs.push(Math.abs(d[mx] - d[nmx]));
          mx = nmx;
          nmx = nmx + width * 4;
        }
        cols.push(diffs.reduce((function(a, b) {
          return a + b;
        }), 0));
      }
      return cols;
    };

    Puzzle.prototype.collatePixelRows = function(imgData, width, height) {
      var col, d, diffs, my, nmy, rows, y, _i, _ref;
      d = imgData.data;
      rows = new Array;
      for (y = _i = 0, _ref = height - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; y = 0 <= _ref ? ++_i : --_i) {
        diffs = new Array;
        col = 0;
        my = y * width * 4;
        nmy = my + 4;
        while (col < width && (d[nmy] != null)) {
          diffs.push(Math.abs(d[my] - d[nmy]));
          my = nmy;
          nmy = nmy + 4;
          col++;
        }
        rows.push(diffs.reduce((function(a, b) {
          return a + b;
        }), 0));
      }
      return rows;
    };

    Puzzle.prototype.calcCrop = function(array, dimension, dimensionType) {
      var fivePercent, total;
      total = array.reduce((function(a, b) {
        return a + b;
      }), 0);
      fivePercent = Math.round(total * .05);
      return this.pingPongCrop(array, dimension, fivePercent, dimensionType);
    };

    Puzzle.prototype.pingPongCrop = function(array, max, target, type) {
      var beat, firstCrop, i, min, ret, secondCrop, sum, v;
      min = 0;
      i = 0;
      sum = 0;
      beat = 'tick';
      firstCrop = [];
      secondCrop = [];
      while (sum <= target) {
        if (beat === 'tick') {
          v = array[min + i];
          firstCrop.push(min + i);
          beat = 'tock';
        } else {
          v = array[(max - 1) - i];
          secondCrop.push(max - i);
          i++;
          beat = 'tick';
        }
        sum += v;
      }
      ret = {};
      if (type === 'cols') {
        ret.left = firstCrop.length;
        ret.right = secondCrop.length;
      } else {
        ret.top = firstCrop.length;
        ret.bottom = secondCrop.length;
      }
      return ret;
    };

    Puzzle.prototype.cropCols = function(canvas, colsToCrop) {
      var ctx, imgData;
      ctx = canvas.getContext('2d');
      imgData = ctx.getImageData(0, 0, canvas.width, canvas.height);
      canvas.width = canvas.width - (colsToCrop.left + colsToCrop.right);
      return ctx.putImageData(imgData, -colsToCrop.left, 0);
    };

    Puzzle.prototype.cropRows = function(canvas, rowsToCrop) {
      var ctx, imgData;
      ctx = canvas.getContext('2d');
      imgData = ctx.getImageData(0, 0, canvas.width, canvas.height);
      canvas.height = canvas.height - (rowsToCrop.top + rowsToCrop.bottom);
      return ctx.putImageData(imgData, 0, -rowsToCrop.top);
    };

    return Puzzle;

  })();

}).call(this);
