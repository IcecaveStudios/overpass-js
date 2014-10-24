(function() {
  var JsonSerialization;

  module.exports = JsonSerialization = (function() {
    function JsonSerialization() {}

    JsonSerialization.prototype.serialize = function(payload) {
      var _ref;
      if (((_ref = typeof payload) !== 'object' && _ref !== 'array') || payload === null) {
        throw new Error('Payload must be an object or an array.');
      }
      return new Buffer(JSON.stringify(payload));
    };

    JsonSerialization.prototype.unserialize = function(buffer) {
      var payload, _ref;
      try {
        payload = JSON.parse(buffer.toString());
      } catch (_error) {
        throw new Error('Could not unserialize payload.');
      }
      if (((_ref = typeof payload) !== 'object' && _ref !== 'array') || payload === null) {
        throw new Error('Payload must be an object or an array.');
      }
      return payload;
    };

    return JsonSerialization;

  })();

}).call(this);

//# sourceMappingURL=JsonSerialization.js.map
