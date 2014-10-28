(function() {
  var InvalidArgumentsException, ResponseCode,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ResponseCode = require('../message/ResponseCode');

  module.exports = InvalidArgumentsException = (function(_super) {
    __extends(InvalidArgumentsException, _super);

    function InvalidArgumentsException(message) {
      this.message = message;
      this.responseCode = ResponseCode.INVALID_ARGUMENTS;
    }

    return InvalidArgumentsException;

  })(Error);

}).call(this);

//# sourceMappingURL=InvalidArgumentsException.js.map
