(function() {
  var AsyncBinaryState, EventEmitter, Subscription, bluebird,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require("events").EventEmitter;

  bluebird = require("bluebird");

  AsyncBinaryState = require("../AsyncBinaryState");

  module.exports = Subscription = (function(_super) {
    __extends(Subscription, _super);

    function Subscription(subscriber, topic) {
      this.subscriber = subscriber;
      this.topic = topic;
      this._message = __bind(this._message, this);
      this._state = new AsyncBinaryState();
    }

    Subscription.prototype.enable = function() {
      return this._state.setOn((function(_this) {
        return function() {
          return _this.subscriber.subscribe(_this.topic).then(function() {
            return _this.subscriber.on("message." + _this.topic, _this._message);
          });
        };
      })(this));
    };

    Subscription.prototype.disable = function() {
      return this._state.setOff((function(_this) {
        return function() {
          return _this.subscriber.unsubscribe(_this.topic).then(function() {
            return _this.subscriber.removeListener("message." + _this.topic, _this._message);
          });
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
