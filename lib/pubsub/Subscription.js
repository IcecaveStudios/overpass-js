(function() {
  var EventEmitter, Subscription, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require("events").EventEmitter;

  bluebird = require("bluebird");

  module.exports = Subscription = (function(_super) {
    __extends(Subscription, _super);

    function Subscription(subscriber, topic) {
      this.subscriber = subscriber;
      this.topic = topic;
      this._message = __bind(this._message, this);
      this._isSubscribed = false;
      this._promise = bluebird.resolve();
    }

    Subscription.prototype.enable = function() {
      if (this._promise.isRejected()) {
        this._promise = bluebird.resolve();
      }
      return this._promise = this._promise.then((function(_this) {
        return function() {
          return _this._subscribe();
        };
      })(this));
    };

    Subscription.prototype.disable = function() {
      if (this._promise.isRejected()) {
        this._promise = bluebird.resolve();
      }
      return this._promise = this._promise.then((function(_this) {
        return function() {
          return _this._unsubscribe();
        };
      })(this));
    };

    Subscription.prototype._subscribe = function() {
      if (this._isSubscribed) {
        return bluebird.resolve();
      }
      this._isSubscribed = true;
      return this.subscriber.subscribe(this.topic).then((function(_this) {
        return function() {
          return _this.subscriber.on("message." + _this.topic, _this._message);
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._isSubscribed = false;
          throw error;
        };
      })(this));
    };

    Subscription.prototype._unsubscribe = function() {
      if (!this._isSubscribed) {
        return bluebird.resolve();
      }
      this._isSubscribed = false;
      return this.subscriber.unsubscribe(this.topic).then((function(_this) {
        return function() {
          return _this.subscriber.removeListener("message." + _this.topic, _this._message);
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          _this._isSubscribed = true;
          throw error;
        };
      })(this));
    };

    Subscription.prototype._message = function(topic, payload) {
      return this.emit("message", topic, payload);
    };

    return Subscription;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Subscription.js.map
