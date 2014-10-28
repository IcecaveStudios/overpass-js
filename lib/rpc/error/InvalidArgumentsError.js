(function() {
  var InvalidArgumentsError, ResponseCode,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ResponseCode = require('../message/ResponseCode');

  module.exports = InvalidArgumentsError = (function(_super) {
    __extends(InvalidArgumentsError, _super);

    function InvalidArgumentsError(message) {
      this.message = message;
      this.responseCode = ResponseCode.INVALID_ARGUMENTS;
    }

    return InvalidArgumentsError;

  })(Error);

}).call(this);

//# sourceMappingURL=InvalidArgumentsError.js.map
