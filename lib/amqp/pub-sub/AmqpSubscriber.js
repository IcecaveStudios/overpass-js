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
      this._promises = {};
      this._topicStates = {};
    }

    AmqpSubscriber.prototype.subscribe = function(topic) {
      topic = this._normalizeTopic(topic);
      switch (this._state(topic)) {
        case 'subscribed':
          return bluebird.resolve();
        case 'subscribing':
          return this._promises[topic];
        case 'unsubscribed':
          this._setState(topic, 'subscribing');
          return this._promises[topic] = this._doSubscribe(topic);
        case 'unsubscribing':
          this._setState(topic, 'subscribing');
          return this._promises[topic] = this._promises[topic].then((function(_this) {
            return function() {
              return _this._doSubscribe(topic);
            };
          })(this));
      }
    };

    AmqpSubscriber.prototype.unsubscribe = function(topic) {
      topic = this._normalizeTopic(topic);
      switch (this._state(topic)) {
        case 'subscribed':
          this._setState(topic, 'unsubscribing');
          return this._promises[topic] = this._doUnsubscribe(topic);
        case 'subscribing':
          this._setState(topic, 'unsubscribing');
          return this._promises[topic] = this._promises[topic].then((function(_this) {
            return function() {
              return _this._doUnsubscribe(topic);
            };
          })(this));
        case 'unsubscribed':
          return bluebird.resolve();
        case 'unsubscribing':
          return this._promises[topic];
      }
    };

    AmqpSubscriber.prototype._doSubscribe = function(topic) {
      var subscription;
      subscription = bluebird.join(this.declarationManager.queue(), this.declarationManager.exchange(), (function(_this) {
        return function(queue, exchange) {
          return _this.channel.bindQueue(queue, exchange, topic);
        };
      })(this));
      return subscription.then((function(_this) {
        return function() {
          return _this._setState(topic, 'subscribed');
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._setState(topic, 'unsubscribed');
          throw error;
        };
      })(this));
    };

    AmqpSubscriber.prototype._doUnsubscribe = function(topic) {
      var unsubscription;
      unsubscription = bluebird.join(this.declarationManager.queue(), this.declarationManager.exchange(), (function(_this) {
        return function(queue, exchange) {
          return _this.channel.unbindQueue(queue, exchange, topic);
        };
      })(this));
      return unsubscription.then((function(_this) {
        return function() {
          return _this._setState(topic, 'unsubscribed');
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._setState(topic, 'subscribed');
          throw error;
        };
      })(this));
    };

    AmqpSubscriber.prototype._normalizeTopic = function(topic) {
      return topic.replace(/\*/g, '#').replace(/\?/g, '*');
    };

    AmqpSubscriber.prototype._state = function(topic) {
      var _ref;
      return (_ref = this._topicStates[topic]) != null ? _ref : 'unsubscribed';
    };

    AmqpSubscriber.prototype._setState = function(topic, state) {
      if (state === 'unsubscribed') {
        return delete this._topicStates[topic];
      } else {
        return this._topicStates[topic] = state;
      }
    };

    return AmqpSubscriber;

  })();

}).call(this);

//# sourceMappingURL=AmqpSubscriber.js.map
