(function() {
  var JsonSerialization, SerializeError, UnserializeError;

  SerializeError = require('./error/SerializeError');

  UnserializeError = require('./error/UnserializeError');

  module.exports = JsonSerialization = (function() {
    function JsonSerialization() {}

    JsonSerialization.prototype.serialize = function(payload) {
      var _ref;
      if (((_ref = typeof payload) !== 'object' && _ref !== 'array') || payload === null) {
        throw new SerializeError();
      }
      return JSON.stringify(payload);
    };

    JsonSerialization.prototype.unserialize = function(buffer) {
      var e, payload, _ref;
      if (typeof buffer !== 'string') {
        throw new UnserializeError();
      }
      try {
        payload = JSON.parse(buffer);
      } catch (_error) {
        e = _error;
        throw new UnserializeError(e);
      }
      if (((_ref = typeof payload) !== 'object' && _ref !== 'array') || payload === null) {
        throw new UnserializeError();
      }
      return payload;
    };

    return JsonSerialization;

  })();

}).call(this);

//# sourceMappingURL=JsonSerialization.js.map
