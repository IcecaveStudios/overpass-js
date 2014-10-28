(function() {
  var InvalidMessageError, JsonSerialization, MessageSerialization, Response, ResponseCode;

  InvalidMessageError = require('../../error/InvalidMessageError');

  JsonSerialization = require('../../../serialization/JsonSerialization');

  Response = require('../Response');

  ResponseCode = require('../ResponseCode');

  module.exports = MessageSerialization = (function() {
    function MessageSerialization(serialization) {
      this.serialization = serialization != null ? serialization : new JsonSerialization();
    }

    MessageSerialization.prototype.serializeRequest = function(request) {
      return this.serialization.serialize([request.name, request["arguments"]]);
    };

    MessageSerialization.prototype.unserializeResponse = function(buffer) {
      var code, e, payload, value;
      try {
        payload = this.serialization.unserialize(buffer);
      } catch (_error) {
        e = _error;
        throw new InvalidMessageError('Response payload is invalid.');
      }
      if (!(payload instanceof Array) || payload.length !== 2) {
        throw new InvalidMessageError('Response payload must be a 2-tuple.');
      }
      code = payload[0], value = payload[1];
      if (!(code = ResponseCode.get(code))) {
        throw new InvalidMessageError('Response code is unrecognised.');
      }
      if (code !== ResponseCode.SUCCESS && !(value instanceof String)) {
        throw new InvalidMessageError('Response error message must be a string.');
      }
      return new Response(code, value);
    };

    return MessageSerialization;

  })();

}).call(this);

//# sourceMappingURL=MessageSerialization.js.map
