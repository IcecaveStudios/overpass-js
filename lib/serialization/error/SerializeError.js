(function() {
  var SerializeError,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module.exports = SerializeError = (function(_super) {
    __extends(SerializeError, _super);

    function SerializeError() {
      this.message = 'Could not serialize payload.';
    }

    return SerializeError;

  })(Error);

}).call(this);
