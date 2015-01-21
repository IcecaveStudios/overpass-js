(function() {
  var AsyncBinaryState, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  bluebird = require("bluebird");

  module.exports = AsyncBinaryState = (function() {
    function AsyncBinaryState(isOn) {
      this.isOn = isOn != null ? isOn : false;
      this._set = __bind(this._set, this);
      this.set = __bind(this.set, this);
      this.setOff = __bind(this.setOff, this);
      this.setOn = __bind(this.setOn, this);
      this._targetState = this.isOn;
      this._promise = bluebird.resolve();
    }

    AsyncBinaryState.prototype.setOn = function(handler) {
      return this.set(true, handler);
    };

    AsyncBinaryState.prototype.setOff = function(handler) {
      return this.set(false, handler);
    };

    AsyncBinaryState.prototype.set = function(isOn, handler) {
      var callback;
      callback = (function(_this) {
        return function() {
          return _this._set(isOn, handler);
        };
      })(this);
      return this._promise = this._promise.then(callback, callback);
    };

    AsyncBinaryState.prototype._set = function(isOn, handler) {
      var method;
      if (isOn === this._targetState) {
        return bluebird.resolve();
      }
      this._targetState = isOn;
      if (handler != null) {
        method = bluebird.method(handler);
      } else {
        method = function() {
          return bluebird.resolve();
        };
      }
      return method().tap((function(_this) {
        return function() {
          return _this.isOn = isOn;
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._targetState = !isOn;
          throw error;
        };
      })(this));
    };

    return AsyncBinaryState;

  })();

}).call(this);

//# sourceMappingURL=AsyncBinaryState.js.map
