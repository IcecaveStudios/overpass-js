(function() {
  var AmqpFactory, AmqpPublisher, AmqpRpcClient, AmqpSubscriberDriver, Subscriber;

  AmqpPublisher = require("./pubsub/AmqpPublisher");

  AmqpRpcClient = require("./rpc/AmqpRpcClient");

  AmqpSubscriberDriver = require("./pubsub/AmqpSubscriberDriver");

  Subscriber = require("../pubsub/Subscriber");

  module.exports = AmqpFactory = (function() {
    function AmqpFactory(connection, logger) {
      this.connection = connection;
      this.logger = logger != null ? logger : require("winston");
    }

    AmqpFactory.prototype.createPublisher = function() {
      return this.connection.createChannel().then((function(_this) {
        return function(channel) {
          return new AmqpPublisher(channel, null, null, _this.logger);
        };
      })(this));
    };

    AmqpFactory.prototype.createSubscriber = function() {
      return this.connection.createChannel().then((function(_this) {
        return function(channel) {
          return new Subscriber(new AmqpSubscriberDriver(channel), _this.logger);
        };
      })(this));
    };

    AmqpFactory.prototype.createRpcClient = function(timeout) {
      if (timeout == null) {
        timeout = null;
      }
      return this.connection.createChannel().then((function(_this) {
        return function(channel) {
          return new AmqpRpcClient(channel, timeout, null, null, _this.logger);
        };
      })(this));
    };

    return AmqpFactory;

  })();

}).call(this);

//# sourceMappingURL=AmqpFactory.js.map
