(function() {
  var GzipEncoding, Promise, bluebird, zlib,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  bluebird = require("bluebird");

  zlib = require('zlib');

  Promise = bluebird.Promise;

  module.exports = GzipEncoding = (function() {
    function GzipEncoding() {
      this.decode = __bind(this.decode, this);
      this.encode = __bind(this.encode, this);
      this._isEnabled = true;
    }

    GzipEncoding.prototype.encode = function(scheme, buffer) {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          if (scheme === null) {
            scheme = 'gzip';
          }
          if (_this._isEnabled && scheme === 'gzip') {
            return zlib.gzip(buffer, function(err, result) {
              return resolve([result, 'gzip']);
            });
          }
          return resolve([buffer, null]);
        };
      })(this));
    };

    GzipEncoding.prototype.decode = function(scheme, buffer) {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          if (_this._isEnabled && scheme === 'gzip') {
            return zlib.gunzip(buffer, function(err, result) {
              return resolve(result);
            });
          }
          throw new Error('Unsupported encoding scheme: ' + scheme + '.');
        };
      })(this));
    };

    return GzipEncoding;

  })();

}).call(this);

//# sourceMappingURL=GzipEncoding.js.map
