(function() {
  var DeclarationManager, Promise;

  Promise = require('bluebird').Promise;

  module.exports = DeclarationManager = (function() {
    function DeclarationManager(channel) {
      this.channel = channel;
      this._exchange = void 0;
    }

    DeclarationManager.prototype.exchange = function() {
      if ((this._exchange != null) && !this._exchange.isRejected()) {
        return this._exchange;
      }
      return this._exchange = this.channel.assertExchange('overpass.pubsub', 'topic', {
        durable: false,
        autoDelete: false
      }).then(function(response) {
        return response.exchange;
      });
    };

    return DeclarationManager;

  })();

}).call(this);

//# sourceMappingURL=DeclarationManager.js.map
