// Generated by CoffeeScript 1.12.3
(function() {
  var EventEmitter, Subscriber, Subscription, Topic, bluebird, regexEscape,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  EventEmitter = require("events").EventEmitter;

  bluebird = require("bluebird");

  regexEscape = require("escape-string-regexp");

  Subscription = require("./Subscription");

  Topic = (function() {
    function Topic(name1) {
      this.name = name1;
      this.promise = bluebird.resolve();
      this.subscriptions = 0;
    }

    return Topic;

  })();

  module.exports = Subscriber = (function(superClass) {
    extend(Subscriber, superClass);

    function Subscriber(driver, logger) {
      this.driver = driver;
      this.logger = logger != null ? logger : require("winston");
      this._message = bind(this._message, this);
      this._unsubscribe = bind(this._unsubscribe, this);
      this._subscribe = bind(this._subscribe, this);
      this._topics = {};
      this._wildcardListeners = {};
      this.on("newListener", this._newListener);
      this.on("removeListener", this._removeListener);
      this.driver.on("message", this._message);
    }

    Subscriber.prototype.create = function(topic) {
      return new Subscription(this, topic);
    };

    Subscriber.prototype.subscribe = function(topic) {
      var callback;
      topic = this._topic(topic);
      callback = (function(_this) {
        return function() {
          return _this._subscribe(topic);
        };
      })(this);
      return topic.promise = topic.promise.then(callback, callback);
    };

    Subscriber.prototype.unsubscribe = function(topic) {
      var callback;
      topic = this._topic(topic);
      callback = (function(_this) {
        return function() {
          return _this._unsubscribe(topic);
        };
      })(this);
      return topic.promise = topic.promise.then(callback, callback);
    };

    Subscriber.prototype._topic = function(name) {
      var base;
      return (base = this._topics)[name] != null ? base[name] : base[name] = new Topic(name);
    };

    Subscriber.prototype._subscribe = function(topic) {
      var isSubscribed;
      isSubscribed = topic.subscriptions > 0;
      ++topic.subscriptions;
      if (isSubscribed) {
        return bluebird.resolve();
      }
      return this.driver.subscribe(topic.name).tap((function(_this) {
        return function() {
          return _this.logger.debug('Subscribed to topic "{topic}"', {
            topic: topic.name
          });
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          --topic.subscriptions;
          throw error;
        };
      })(this));
    };

    Subscriber.prototype._unsubscribe = function(topic) {
      if (topic.subscriptions < 1) {
        return bluebird.resolve();
      }
      --topic.subscriptions;
      if (topic.subscriptions > 0) {
        return bluebird.resolve();
      }
      return this.driver.unsubscribe(topic.name).tap((function(_this) {
        return function() {
          return _this.logger.debug('Unsubscribed from topic "{topic}"', {
            topic: topic.name
          });
        };
      })(this))["catch"]((function(_this) {
        return function(error) {
          ++topic.subscriptions;
          throw error;
        };
      })(this));
    };

    Subscriber.prototype._message = function(topic, payload) {
      var event, ref, regex, results;
      this.logger.debug('Received {payload} from topic "{topic}"', {
        topic: topic,
        payload: JSON.stringify(payload)
      });
      this.emit("message", topic, payload);
      this.emit("message." + topic, topic, payload);
      ref = this._wildcardListeners;
      results = [];
      for (event in ref) {
        regex = ref[event];
        if (regex.test(topic)) {
          results.push(this.emit(event, topic, payload));
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    Subscriber.prototype._newListener = function(event, listener) {
      var atom, atoms, isPattern, pattern;
      if (event in this._wildcardListeners) {
        return;
      }
      atoms = event.split(".");
      if (atoms.shift() !== "message") {
        return;
      }
      isPattern = false;
      atoms = (function() {
        var i, len, results;
        results = [];
        for (i = 0, len = atoms.length; i < len; i++) {
          atom = atoms[i];
          switch (atom) {
            case "*":
              isPattern = true;
              results.push("(.+)");
              break;
            case "?":
              isPattern = true;
              results.push("([^.]+)");
              break;
            default:
              results.push(regexEscape(atom));
          }
        }
        return results;
      })();
      if (isPattern) {
        pattern = "^" + (atoms.join(regexEscape("."))) + "$";
        return this._wildcardListeners[event] = new RegExp(pattern);
      }
    };

    Subscriber.prototype._removeListener = function(event, listener) {
      if (!EventEmitter.listenerCount(this, event)) {
        return delete this._wildcardListeners[event];
      }
    };

    return Subscriber;

  })(EventEmitter);

}).call(this);

//# sourceMappingURL=Subscriber.js.map
