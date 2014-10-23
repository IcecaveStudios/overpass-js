(function() {
  var AmqpPublisher, DeclarationManager, JsonSerialization;

  DeclarationManager = require('./DeclarationManager');

  JsonSerialization = require('../../serialization/JsonSerialization');

  module.exports = AmqpPublisher = (function() {
    function AmqpPublisher(channel, declarationManager, serialization) {
      this.channel = channel;
      this.declarationManager = declarationManager != null ? declarationManager : new DeclarationManager(this.channel);
      this.serialization = serialization != null ? serialization : new JsonSerialization();
    }

    AmqpPublisher.prototype.publish = function(topic, payload) {
      return this.declarationManager.exchange().then((function(_this) {
        return function(exchange) {
          return _this.channel.publish(exchange, topic, _this.serialization.serialize(payload));
        };
      })(this));
    };

    return AmqpPublisher;

  })();

}).call(this);

//# sourceMappingURL=AmqpPublisher.js.map
