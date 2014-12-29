(function() {
  var InvalidMessageError, ResponseCode,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ResponseCode = require("../message/ResponseCode");

  module.exports = InvalidMessageError = (function(_super) {
    __extends(InvalidMessageError, _super);

    function InvalidMessageError(message) {
      this.message = message;
      this.responseCode = ResponseCode.INVALID_MESSAGE;
    }

    return InvalidMessageError;

  })(Error);

}).call(this);

//# sourceMappingURL=InvalidMessageError.js.map
