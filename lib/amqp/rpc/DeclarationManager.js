(function() {
  var DeclarationManager, bluebird;

  bluebird = require('bluebird');

  module.exports = DeclarationManager = (function() {
    function DeclarationManager(channel) {
      this.channel = channel;
      this._exchange = null;
      this._requestQueues = {};
      this._responseQueue = null;
    }

    DeclarationManager.prototype.exchange = function() {
      if ((this._exchange != null) && !this._exchange.isRejected()) {
        return this._exchange;
      }
      return this._exchange = bluebird.resolve(this.channel.assertExchange('overpass/rpc', 'direct', {
        autoDelete: false,
        durable: false
      })).then(function(response) {
        return response.exchange;
      });
    };

    DeclarationManager.prototype.requestQueue = function(procedureName) {
      if (this._requestQueues[procedureName] != null) {
        if (!this._requestQueues[procedureName].isRejected()) {
          return this._requestQueues[procedureName];
        }
      }
      return this._requestQueues[procedureName] = bluebird.resolve(this.channel.assertQueue('overpass/rpc/' + procedureName, {
        exclusive: false,
        autoDelete: false,
        durable: false
      })).then(function(response) {
        return response.queue;
      });
    };

    DeclarationManager.prototype.responseQueue = function() {
      if ((this._responseQueue != null) && !this._responseQueue.isRejected()) {
        return this._responseQueue;
      }
      return this._responseQueue = bluebird.resolve(this.channel.assertQueue(null, {
        exclusive: true,
        autoDelete: true,
        durable: false
      })).then(function(response) {
        return response.queue;
      });
    };

    return DeclarationManager;

  })();

}).call(this);

//# sourceMappingURL=DeclarationManager.js.map
