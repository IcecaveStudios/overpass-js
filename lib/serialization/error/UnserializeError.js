(function() {
  var UnserializeError,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = UnserializeError = (function(_super) {
    __extends(UnserializeError, _super);

    function UnserializeError(cause) {
      this.message = 'Could not unserialize payload.';
      this.cause = cause;
    }

    return UnserializeError;

  })(Error);

}).call(this);

//# sourceMappingURL=UnserializeError.js.map
