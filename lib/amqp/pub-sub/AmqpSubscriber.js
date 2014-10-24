(function() {
  var AmqpSubscriber, DeclarationManager, JsonSerialization, bluebird;

  bluebird = require('bluebird');

  DeclarationManager = require('./DeclarationManager');

  JsonSerialization = require('../../serialization/JsonSerialization');

  module.exports = AmqpSubscriber = (function() {
    function AmqpSubscriber(channel, declarationManager, serialization) {
      this.channel = channel;
      this.declarationManager = declarationManager != null ? declarationManager : new DeclarationManager(this.channel);
      this.serialization = serialization != null ? serialization : new JsonSerialization();
      this._subscriptions = {};
      this._unsubscriptions = {};
    }

    AmqpSubscriber.prototype.subscribe = function(topic) {
      var subscription;
      topic = this._normalizeTopic(topic);
      if ((this._subscriptions[topic] != null) && !this._subscriptions[topic].isRejected()) {
        return this._subscriptions[topic];
      }
      subscription = bluebird.join(this.declarationManager.queue(), this.declarationManager.exchange(), (function(_this) {
        return function(queue, exchange) {
          return _this.channel.bindQueue(queue, exchange, topic);
        };
      })(this));
      subscription = subscription.then((function(_this) {
        return function() {
          if ((_this._unsubscriptions[topic] != null) && !_this._unsubscriptions[topic].isPending()) {
            return delete _this._unsubscriptions[topic];
          }
        };
      })(this));
      if ((this._unsubscriptions[topic] != null) && this._unsubscriptions[topic].isPending()) {
        subscription = this._unsubscriptions[topic].then(bluebird.resolve(subscription), bluebird.resolve(subscription));
      }
      return this._subscriptions[topic] = subscription;
    };

    AmqpSubscriber.prototype._normalizeTopic = function(topic) {
      return topic.replace(/\*/g, '#').replace(/\?/g, '*');
    };

    return AmqpSubscriber;

  })();

}).call(this);

//# sourceMappingURL=AmqpSubscriber.js.map
