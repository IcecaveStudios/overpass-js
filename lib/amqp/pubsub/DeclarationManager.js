(function() {
  var DeclarationManager, bluebird;

  bluebird = require('bluebird');

  module.exports = DeclarationManager = (function() {
    function DeclarationManager(channel) {
      this.channel = channel;
      this._exchange = null;
      this._queue = null;
    }

    DeclarationManager.prototype.exchange = function() {
      if ((this._exchange != null) && !this._exchange.isRejected()) {
        return this._exchange;
      }
      return this._exchange = bluebird.resolve(this.channel.assertExchange('overpass/pubsub', 'topic', {
        autoDelete: false,
        durable: false
      })).then(function(response) {
        return response.exchange;
      });
    };

    DeclarationManager.prototype.queue = function() {
      if ((this._queue != null) && !this._queue.isRejected()) {
        return this._queue;
      }
      return this._queue = bluebird.resolve(this.channel.assertQueue(null, {
        exclusive: true,
        autoDelete: true,
        durable: false,
        noAck: true
      })).then(function(response) {
        return response.queue;
      });
    };

    return DeclarationManager;

  })();

}).call(this);

//# sourceMappingURL=DeclarationManager.js.map
