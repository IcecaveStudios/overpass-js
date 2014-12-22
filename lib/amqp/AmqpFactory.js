(function() {
  var AmqpFactory;

  module.exports = AmqpFactory = (function() {
    function AmqpFactory(connection, rpcTimeout, logger) {
      this.connection = connection;
      this.rpcTimeout = rpcTimeout != null ? rpcTimeout : 3;
      this.logger = logger != null ? logger : require("winston");
    }

    AmqpFactory.prototype.createPublisher = function() {
      return this.connection.createChannel().then((function(_this) {
        return function(channel) {
          return new Publisher(channel, _this.logger);
        };
      })(this));
    };

    AmqpFactory.prototype.createSubscriber = function() {
      return this.connection.createChannel().then((function(_this) {
        return function(channel) {
          var driver;
          driver = new AmqpSubscriberDriver(channel);
          return new Subscriber(driver, _this.logger);
        };
      })(this));
    };

    AmqpFactory.prototype.createRpcClient = function() {
      return this.connection.createChannel().then((function(_this) {
        return function(channel) {
          return new AmqpRpcClient(channel, _this.rpcTimeout, null, null, _this.logger);
        };
      })(this));
    };

    return AmqpFactory;

  })();

}).call(this);

//# sourceMappingURL=AmqpFactory.js.map
