(function() {
  var EventEmitter, Subscriber, Subscription, Topic, bluebird, regexEscape,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EventEmitter = require("events").EventEmitter;

  bluebird = require("bluebird");

  regexEscape = require("escape-string-regexp");

  Subscription = require("./Subscription");

  Topic = (function() {
    function Topic(name) {
      this.name = name;
      this.promise = bluebird.resolve();
      this.subscriptions = 0;
    }

    return Topic;

  })();

  module.exports = Subscriber = (function(_super) {
    __extends(Subscriber, _super);

    function Subscriber(driver, logger) {
      this.driver = driver;
      this.logger = logger != null ? logger : require("winston");
      this._message = __bind(this._message, this);
      this._unsubscribe = __bind(this._unsubscribe, this);
      this._subscribe = __bind(this._subscribe, this);
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
      var _base;
      return (_base = this._topics)[name] != null ? _base[name] : _base[name] = new Topic(name);
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
      var event, regex, _ref, _results;
      this.logger.debug('Received {payload} from topic "{topic}"', {
        topic: topic,
        payload: JSON.stringify(payload)
      });
      this.emit("message", topic, payload);
      this.emit("message." + topic, topic, payload);
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
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = atoms.length; _i < _len; _i++) {
          atom = atoms[_i];
          switch (atom) {
            case "*":
              isPattern = true;
              _results.push("(.+)");
              break;
            case "?":
              isPattern = true;
              _results.push("([^.]+)");
              break;
            default:
              _results.push(regexEscape(atom));
          }
        }
        return _results;
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
