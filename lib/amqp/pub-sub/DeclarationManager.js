(function() {
  var DeclarationManager;

  module.exports = DeclarationManager = (function() {
    function DeclarationManager(channel) {
      this.channel = channel;
    }

    DeclarationManager.prototype.exchange = function() {
      var p;
      p = this.channel.assertExchange('overpass.pubsub', 'topic', {
        durable: false,
        autoDelete: false
      });
      return p.then(function(response) {
        return response.exchange;
      });
    };

    return DeclarationManager;

  })();

}).call(this);

//# sourceMappingURL=DeclarationManager.js.map
