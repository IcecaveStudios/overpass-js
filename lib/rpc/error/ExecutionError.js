(function() {
  var ExecutionError, ResponseCode,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ResponseCode = require('../message/ResponseCode');

  module.exports = ExecutionError = (function(_super) {
    __extends(ExecutionError, _super);

    function ExecutionError(message) {
      this.message = message;
      this.responseCode = ResponseCode.EXCEPTION;
    }

    return ExecutionError;

  })(Error);

}).call(this);

//# sourceMappingURL=ExecutionError.js.map
