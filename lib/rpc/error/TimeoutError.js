(function() {
  var TimeoutError,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = TimeoutError = (function(_super) {
    __extends(TimeoutError, _super);

    function TimeoutError(timeout) {
      this.timeout = timeout;
      this.message = "RPC call timed out after " + this.timeout + " seconds.";
    }

    return TimeoutError;

  })(Error);

}).call(this);

//# sourceMappingURL=TimeoutError.js.map
