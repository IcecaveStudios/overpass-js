(function() {
  var AmqpRpcClient, DeclarationManager, MessageSerialization, Request, bluebird;

  bluebird = require('bluebird');

  DeclarationManager = require('./DeclarationManager');

  MessageSerialization = require('../../rpc/message/serialization/MessageSerialization');

  Request = require('../../rpc/message//Request');

  module.exports = AmqpRpcClient = (function() {
    function AmqpRpcClient(channel, timeout, declarationManager, serialization, logger) {
      this.channel = channel;
      this.timeout = timeout != null ? timeout : 10;
      this.declarationManager = declarationManager != null ? declarationManager : new DeclarationManager(this.channel);
      this.serialization = serialization != null ? serialization : new MessageSerialization();
      this.logger = logger != null ? logger : require('winston');
      this._initializer = null;
      this._requests = {};
      this._id = 0;
    }

    AmqpRpcClient.prototype.call = function(name, args) {
      return this._initialize().then((function(_this) {
        return function() {
          var id, request;
          id = ++_this._id;
          request = new Request(name, args);
          _this.logger.debug('RPC #{id} {request}', {
            id: id,
            request: request.toString()
          });
          return _this._send(request, id);
        };
      })(this));
    };

    AmqpRpcClient.prototype._initialize = function() {
      if ((this._initializer != null) && !this._initializer.isRejected()) {
        return this._initializer;
      }
      return this._initializer = this.declarationManager.responseQueue().then((function(_this) {
        return function(queue) {
          return _this.channel.consume(queue, function(message) {
            return _this._recv(message);
          });
        };
      })(this));
    };

    AmqpRpcClient.prototype._send = function(request, id) {
      var payload, promise, timeout;
      payload = this.serialization.serializeRequest(request);
      promise = new bluebird.Promise(function(resolve, reject) {
        return this._requests[id] = {
          resolve: resolve,
          reject: reject
        };
      });
      timeout = Math.round(this.timeout * 1000);
      bluebird.join(this.declarationManager.responseQueue(), this.declarationManager.requestQueue(request.name), this.declarationManager.exchange(), (function(_this) {
        return function(responseQueue, requestQueue, exchange) {
          return _this.channel.publish(exchange, request.name, payload, {
            replyTo: responseQueue,
            correlationId: id,
            expiration: timeout
          });
        };
      })(this))["catch"](function(e) {
        this._requests[id].reject(e);
        throw e;
      });
      return promise.timeout(timeout, 'RPC request timed out.')["finally"](function() {
        return delete this._requests[id];
      });
    };

    AmqpRpcClient.prototype._recv = function(message) {
      var e, id, response;
      id = message.properties.correlationId;
      if (id == null) {
        return this.logger.warn('Received RPC response with no correlation ID');
      }
      if (this._requests[id] == null) {
        return this.logger.warn('Received RPC response with unknown correlation ID');
      }
      try {
        response = this.serialization.unserializeResponse(message.content).extract();
        return this._requests[id].resolve(response);
      } catch (_error) {
        e = _error;
        this._requests[id].reject(e);
        throw e;
      }
    };

    return AmqpRpcClient;

  })();

}).call(this);

//# sourceMappingURL=AmqpRpcClient.js.map
