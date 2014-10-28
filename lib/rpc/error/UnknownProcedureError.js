(function() {
  var ResponseCode, UnknownProcedureError,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ResponseCode = require('../message/ResponseCode');

  module.exports = UnknownProcedureError = (function(_super) {
    __extends(UnknownProcedureError, _super);

    function UnknownProcedureError(procedureName) {
      this.procedureName = procedureName;
      this.message = 'Unknown procedure: ' + this.procedureName + '.';
      this.responseCode = ResponseCode.UNKNOWN_PROCEDURE;
    }

    return UnknownProcedureError;

  })(Error);

}).call(this);

//# sourceMappingURL=UnknownProcedureError.js.map
