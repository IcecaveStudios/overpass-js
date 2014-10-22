(function() {
  var JsonSerialization, SerializeError, UnserializeError;

  SerializeError = require('./error/SerializeError');

  UnserializeError = require('./error/UnserializeError');

  module.exports = JsonSerialization = (function() {
    function JsonSerialization() {}

    JsonSerialization.prototype.serialize = function(payload) {
      var type;
      type = typeof payload;
      if (type === 'undefined') {
        return 'null';
      }
      if (type !== 'object' && type !== 'boolean' && type !== 'number' && type !== 'string') {
        throw new SerializeError();
      }
      return JSON.stringify(payload);
    };

    JsonSerialization.prototype.unserialize = function(buffer) {
      var e;
      if (typeof buffer !== 'string') {
        throw new UnserializeError();
      }
      try {
        return JSON.parse(buffer);
      } catch (_error) {
        e = _error;
        throw new UnserializeError(e);
      }
    };

    return JsonSerialization;

  })();

}).call(this);

//# sourceMappingURL=JsonSerialization.js.map
