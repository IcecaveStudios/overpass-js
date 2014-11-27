(function() {
  var AmqpSubscriber, DeclarationManager, EventEmitter, JsonSerialization, bluebird, regexEscape,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  bluebird = require('bluebird');

  regexEscape = require('escape-string-regexp');

  EventEmitter = require('events').EventEmitter;

  DeclarationManager = require('./DeclarationManager');

  JsonSerialization = require('../../serialization/JsonSerialization');

  module.exports = AmqpSubscriber = (function(_super) {
    __extends(AmqpSubscriber, _super);

    function AmqpSubscriber(channel, declarationManager, serialization, logger) {
      this.channel = channel;
      this.declarationManager = declarationManager != null ? declarationManager : new DeclarationManager(this.channel);
      this.serialization = serialization != null ? serialization : new JsonSerialization();
      this.logger = logger != null ? logger : require('winston');
      this._promises = {};
      this._topicStates = {};
      this._consumer = null;
      this._consumerState = 'detached';
      this._consumerTag = null;
      this._wildcardListeners = {};
      this.on('newListener', this._onNewListener);
      this.on('removeListener', this._onRemoveListener);
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
      return this._consume().then((function(_this) {
        return function() {
          return bluebird.join(_this.declarationManager.queue(), _this.declarationManager.exchange(), function(queue, exchange) {
            return _this.channel.bindQueue(queue, exchange, topic);
          }).then(function() {
            return _this._setState(topic, 'subscribed');
          });
        };
      })(this)).tap((function(_this) {
        return function() {
          return _this.logger.debug('Subscribed to topic "{topic}"', {
            topic: topic
          });
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._setState(topic, 'unsubscribed');
          throw error;
        };
      })(this));
    };

    AmqpSubscriber.prototype._doUnsubscribe = function(topic) {
      return bluebird.join(this.declarationManager.queue(), this.declarationManager.exchange(), (function(_this) {
        return function(queue, exchange) {
          return _this.channel.unbindQueue(queue, exchange, topic);
        };
      })(this)).then((function(_this) {
        return function() {
          return _this._setState(topic, 'unsubscribed');
        };
      })(this)).then((function(_this) {
        return function() {
          if (Object.keys(_this._topicStates).length < 1) {
            return _this._cancelConsume();
          } else {

          }
        };
      })(this)).tap((function(_this) {
        return function() {
          return _this.logger.debug('Unsubscribed from topic "{topic}"', {
            topic: topic
          });
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
          return this._consumer = this._doCancelConsume();
        case 'attaching':
          this._consumerState = 'cancelling';
          return this._consumer = this._consumer.then((function(_this) {
            return function() {
              return _this._doCancelConsume();
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
          var handler;
          handler = function(message) {
            var payload, payloadString, topic;
            topic = message.fields.routingKey;
            payloadString = message.content.toString();
            payload = _this.serialization.unserialize(payloadString);
            _this._emit(topic, payload);
            return _this.logger.debug('Received {payload} from topic "{topic}"', {
              topic: topic,
              payload: payloadString
            });
          };
          return _this.channel.consume(queue, handler, {
            noAck: true
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

    AmqpSubscriber.prototype._doCancelConsume = function() {
      var cancel;
      cancel = this.channel.cancel(this._consumerTag);
      return cancel.then((function(_this) {
        return function() {
          _this._consumerState = 'detached';
          return _this._consumerTag = null;
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._consumerState = 'consuming';
          throw error;
        };
      })(this));
    };

    AmqpSubscriber.prototype._emit = function(topic, payload) {
      var event, regex, _ref, _results;
      this.emit('message', topic, payload);
      this.emit('message.' + topic, topic, payload);
      _ref = this._wildcardListeners;
      _results = [];
      for (event in _ref) {
        regex = _ref[event];
        if (regex.test(topic)) {
          _results.push(this.emit(event, topic, payload));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    AmqpSubscriber.prototype._onNewListener = function(event, listener) {
      var atom, atoms, isPattern, pattern;
      if (event in this._wildcardListeners) {
        return;
      }
      atoms = event.split('.');
      if (atoms.shift() !== 'message') {
        return;
      }
      isPattern = false;
      atoms = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = atoms.length; _i < _len; _i++) {
          atom = atoms[_i];
          switch (atom) {
            case '*':
              isPattern = true;
              _results.push('(.+)');
              break;
            case '?':
              isPattern = true;
              _results.push('([^.]+)');
              break;
            default:
              _results.push(regexEscape(atom));
          }
        }
        return _results;
      })();
      if (isPattern) {
        pattern = "^" + (atoms.join(regexEscape('.'))) + "$";
        return this._wildcardListeners[event] = new RegExp(pattern);
      }
    };

    AmqpSubscriber.prototype._onRemoveListener = function(event, listener) {
      if (!EventEmitter.listenerCount(this, event)) {
        return delete this._wildcardListeners[event];
      }
    };

    return AmqpSubscriber;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=AmqpSubscriber.js.map
