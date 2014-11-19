(function() {
  var AmqpPublisher, DeclarationManager, JsonSerialization;

  DeclarationManager = require('./DeclarationManager');

  JsonSerialization = require('../../serialization/JsonSerialization');

  module.exports = AmqpPublisher = (function() {
    function AmqpPublisher(channel, declarationManager, serialization, logger) {
      this.channel = channel;
      this.declarationManager = declarationManager != null ? declarationManager : new DeclarationManager(this.channel);
      this.serialization = serialization != null ? serialization : new JsonSerialization();
      this.logger = logger != null ? logger : require('winston');
    }

    AmqpPublisher.prototype.publish = function(topic, payload) {
      payload = this.serialization.serialize(payload);
      return this.declarationManager.exchange().then((function(_this) {
        return function(exchange) {
          return _this.channel.publish(exchange, topic, payload);
        };
      })(this)).tap((function(_this) {
        return function() {
          return _this.logger.debug('Published {payload} to topic "{topic}"', {
            topic: topic,
            payload: payload.toString()
          });
        };
      })(this));
    };

    return AmqpPublisher;

  })();

}).call(this);

//# sourceMappingURL=AmqpPublisher.js.map