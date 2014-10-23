(function() {
  var JsonSerialization;

  module.exports = JsonSerialization = (function() {
    function JsonSerialization() {}

    JsonSerialization.prototype.serialize = function(payload) {
      var _ref;
      if (((_ref = typeof payload) !== 'object' && _ref !== 'array') || payload === null) {
        throw new Error('Payload must be an object or an array.');
      }
      return JSON.stringify(payload);
    };

    JsonSerialization.prototype.unserialize = function(buffer) {
      var payload, _ref;
      if (typeof buffer !== 'string') {
        throw new Error('Could not unserialize payload.');
      }
      payload = JSON.parse(buffer);
      if (((_ref = typeof payload) !== 'object' && _ref !== 'array') || payload === null) {
        throw new Error('Payload must be an object or an array.');
      }
      return payload;
    };

    return JsonSerialization;

  })();

}).call(this);

//# sourceMappingURL=JsonSerialization.js.map
