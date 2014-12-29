(function() {
  var AmqpSubscriberDriver, DeclarationManager, EventEmitter, JsonSerialization, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  bluebird = require("bluebird");

  EventEmitter = require("events").EventEmitter;

  DeclarationManager = require("./DeclarationManager");

  JsonSerialization = require("../../serialization/JsonSerialization");

  module.exports = AmqpSubscriberDriver = (function(_super) {
    __extends(AmqpSubscriberDriver, _super);

    function AmqpSubscriberDriver(channel, declarationManager, serialization) {
      this.channel = channel;
      this.declarationManager = declarationManager != null ? declarationManager : new DeclarationManager(this.channel);
      this.serialization = serialization != null ? serialization : new JsonSerialization();
      this._message = __bind(this._message, this);
      this._count = 0;
      this._consumer = bluebird.resolve();
      this._consumerState = "detached";
      this._consumerTag = null;
    }

    AmqpSubscriberDriver.prototype.subscribe = function(topic) {
      topic = this._normalizeTopic(topic);
      ++this._count;
      return this._consume().then((function(_this) {
        return function() {
          return bluebird.join(_this.declarationManager.queue(), _this.declarationManager.exchange(), function(queue, exchange) {
            return _this.channel.bindQueue(queue, exchange, topic);
          });
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          --_this._count;
          throw error;
        };
      })(this));
    };

    AmqpSubscriberDriver.prototype.unsubscribe = function(topic) {
      topic = this._normalizeTopic(topic);
      --this._count;
      return bluebird.join(this.declarationManager.queue(), this.declarationManager.exchange(), (function(_this) {
        return function(queue, exchange) {
          return _this.channel.unbindQueue(queue, exchange, topic);
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          ++_this._count;
          throw error;
        };
      })(this)).then((function(_this) {
        return function() {
          if (!_this._count) {
            return _this._cancelConsume();
          }
        };
      })(this));
    };

    AmqpSubscriberDriver.prototype._normalizeTopic = function(topic) {
      return topic.replace(/\*/g, "#").replace(/\?/g, "*");
    };

    AmqpSubscriberDriver.prototype._consume = function() {
      switch (this._consumerState) {
        case "consuming":
          return this._consumer;
        case "attaching":
          return this._consumer;
        case "detached":
          this._consumerState = "attaching";
          return this._consumer = this._doConsume();
        case "cancelling":
          this._consumerState = "attaching";
          return this._consumer = this._consumer.then((function(_this) {
            return function() {
              return _this._doConsume();
            };
          })(this));
      }
    };

    AmqpSubscriberDriver.prototype._cancelConsume = function() {
      switch (this._consumerState) {
        case "consuming":
          this._consumerState = "cancelling";
          return this._consumer = this._doCancelConsume();
        case "attaching":
          this._consumerState = "cancelling";
          return this._consumer = this._consumer.then((function(_this) {
            return function() {
              return _this._doCancelConsume();
            };
          })(this));
        case "detached":
          return this._consumer;
        case "cancelling":
          return this._consumer;
      }
    };

    AmqpSubscriberDriver.prototype._doConsume = function() {
      var consumer;
      consumer = this.declarationManager.queue().then((function(_this) {
        return function(queue) {
          return _this.channel.consume(queue, _this._message, {
            noAck: true
          });
        };
      })(this));
      return consumer.then((function(_this) {
        return function(response) {
          _this._consumerState = "consuming";
          return _this._consumerTag = response.consumerTag;
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._consumerState = "detached";
          throw error;
        };
      })(this));
    };

    AmqpSubscriberDriver.prototype._doCancelConsume = function() {
      var cancel;
      cancel = this.channel.cancel(this._consumerTag);
      return cancel.then((function(_this) {
        return function() {
          _this._consumerState = "detached";
          return _this._consumerTag = null;
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._consumerState = "consuming";
          throw error;
        };
      })(this));
    };

    AmqpSubscriberDriver.prototype._message = function(message) {
      var payload, payloadString, topic;
      topic = message.fields.routingKey;
      payloadString = message.content.toString();
      payload = this.serialization.unserialize(payloadString);
      return this.emit("message", topic, payload);
    };

    return AmqpSubscriberDriver;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=AmqpSubscriberDriver.js.map
