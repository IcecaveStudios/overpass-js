(function() {
  var EventEmitter, Subscription, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require('event').EventEmitter;

  bluebird = require('bluebird');

  module.exports = Subscription = (function(_super) {
    __extends(Subscription, _super);

    function Subscription(subscriber, topic) {
      this.subscriber = subscriber;
      this.topic = topic;
      this._message = __bind(this._message, this);
      this._state = 'unsubscribed';
      this._promise = null;
    }

    Subscription.prototype.enable = function() {
      switch (this._state) {
        case "subscribed":
          return bluebird.resolve();
        case "subscribing":
          return this._promise;
        case "unsubscribed":
          this._state = "subscribing";
          return this._promise = this._subscribe();
        case "unsubscribing":
          this._state = "subscribing";
          return this._promise = this._promise.then((function(_this) {
            return function() {
              return _this._subscribe();
            };
          })(this));
      }
    };

    Subscription.prototype.disable = function() {
      switch (this._state) {
        case 'subscribed':
          this._state = 'unsubscribing';
          return this._promise = this._unsubscribe();
        case 'subscribing':
          this._state = 'unsubscribing';
          return this._promise = this._promise.then((function(_this) {
            return function() {
              return _this._unsubscribe();
            };
          })(this));
        case 'unsubscribed':
          return bluebird.resolve();
        case 'unsubscribing':
          return this._promise;
      }
    };

    Subscription.prototype._message = function(topic, payload) {
      return this.emit("message", topic, payload);
    };

    Subscription.prototype._subscribe = function() {
      this.subscriber.on("message." + this.topic, this._message);
      return this.subscriber.subscribe(this.topic).tap((function(_this) {
        return function() {
          return _this.emit("subscribe");
        };
      })(this));
    };

    Subscription.prototype._unsubscribe = function() {
      this.subscriber.removeListener("message." + this.topic, this._message);
      return this.subscriber.unsubscribe(this.topic).tap((function(_this) {
        return function() {
          return _this.emit("unsubscribe");
        };
      })(this));
    };

    return Subscription;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Subscription.js.map
