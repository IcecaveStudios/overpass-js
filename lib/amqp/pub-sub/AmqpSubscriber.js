(function() {
  var AmqpSubscriber, DeclarationManager, EventEmitter, JsonSerialization, bluebird,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  bluebird = require('bluebird');

  EventEmitter = require('events').EventEmitter;

  DeclarationManager = require('./DeclarationManager');

  JsonSerialization = require('../../serialization/JsonSerialization');

  module.exports = AmqpSubscriber = (function(_super) {
    __extends(AmqpSubscriber, _super);

    function AmqpSubscriber(channel, declarationManager, serialization) {
      this.channel = channel;
      this.declarationManager = declarationManager != null ? declarationManager : new DeclarationManager(this.channel);
      this.serialization = serialization != null ? serialization : new JsonSerialization();
      this._promises = {};
      this._topicStates = {};
      this._consumer = null;
      this._consumerState = 'detached';
      this._consumerTag = null;
      this.on('newListener', (function(_this) {
        return function(event) {
          if (event === 'message') {
            return _this._onMessageListenerAdded();
          }
        };
      })(this));
      this.on('removeListener', (function(_this) {
        return function(event) {
          if (event === 'message') {
            return _this._onMessageListenerRemoved();
          }
        };
      })(this));
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

    AmqpSubscriber.prototype._onMessageListenerAdded = function() {
      return this._consume();
    };

    AmqpSubscriber.prototype._onMessageListenerRemoved = function() {
      if (EventEmitter.listenerCount(this, 'message') < 1) {
        return this._cancelConsume();
      }
    };

    AmqpSubscriber.prototype._consume = function() {
      switch (this._consumerState) {
        case 'consuming':
          return bluebird.resolve();
        case 'attaching':
          return this._consumer;
        case 'detached':
          this._consumerState = 'attaching';
          return this._consumer = this._doConsume();
        case 'cancelling':
          this._consumerState = 'attaching';
          return this._consumer = this._consumer.then((function(_this) {
            return function() {
              return _this._doConsume();
            };
          })(this));
      }
    };

    AmqpSubscriber.prototype._cancelConsume = function() {
      switch (this._consumerState) {
        case 'consuming':
          this._consumerState = 'cancelling';
          return this._consumer = this._doCancel();
        case 'attaching':
          this._consumerState = 'cancelling';
          return this._consumer = this._consumer.then((function(_this) {
            return function() {
              return _this._doCancel();
            };
          })(this));
        case 'detached':
          return bluebird.resolve();
        case 'cancelling':
          return this._consumer;
      }
    };

    AmqpSubscriber.prototype._doConsume = function() {
      var consumer;
      consumer = this.declarationManager.queue().then((function(_this) {
        return function(queue) {
          return _this.channel.consume(queue, function(message) {
            return _this.emit('message', _this.serialization.unserialize(message.content));
          });
        };
      })(this));
      return consumer.then((function(_this) {
        return function(response) {
          _this._consumerState = 'consuming';
          return _this._consumerTag = response.consumerTag;
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._consumerState = 'detached';
          throw error;
        };
      })(this));
    };

    AmqpSubscriber.prototype._doCancel = function() {
      var cancel;
      cancel = this.channel.cancel(this._consumerTag);
      return cancel.then((function(_this) {
        return function() {
          console.log('finished detaching');
          _this._consumerState = 'detached';
          return _this._consumerTag = null;
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          return _this._consumerState = 'consuming';
        };
      })(this));
    };

    return AmqpSubscriber;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=AmqpSubscriber.js.map
