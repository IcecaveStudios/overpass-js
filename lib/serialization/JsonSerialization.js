(function() {
  var JsonSerialization, SerializeError;

  SerializeError = require('./error/SerializeError');

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

    return JsonSerialization;

  })();

}).call(this);

//# sourceMappingURL=JsonSerialization.js.map
