(function() {
  var AmqpRpcClient, DeclarationManager, MessageSerialization, Promise, Request, ResponseCode, TimeoutError, bluebird,
    __slice = [].slice;

  bluebird = require("bluebird");

  Promise = require("bluebird").Promise;

  TimeoutError = require("bluebird").TimeoutError;

  DeclarationManager = require("./DeclarationManager");

  MessageSerialization = require("../../rpc/message/serialization/MessageSerialization");

  Request = require("../../rpc/message/Request");

  ResponseCode = require("../../rpc/message/ResponseCode");

  module.exports = AmqpRpcClient = (function() {
    function AmqpRpcClient(channel, timeout, declarationManager, serialization, logger) {
      this.channel = channel;
      this.timeout = timeout != null ? timeout : 10;
      this.declarationManager = declarationManager != null ? declarationManager : new DeclarationManager(this.channel);
      this.serialization = serialization != null ? serialization : new MessageSerialization();
      this.logger = logger != null ? logger : require("winston");
      this._initializer = null;
      this._requests = {};
      this._id = 0;
    }

    AmqpRpcClient.prototype.invoke = function() {
      var args, name;
      name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return this._initialize().then((function(_this) {
        return function() {
          var id, request;
          id = (++_this._id).toString();
          request = new Request(name, args);
          _this.logger.debug('RPC #{id} {request}', {
            id: id,
            request: request.toString()
          });
          return _this._send(request, id).then(function(response) {
            var isSuccess, responseBody;
            responseBody = response.toString();
            isSuccess = response.code === ResponseCode.SUCCESS;
            if (isSuccess && responseBody.length > 256) {
              responseBody = responseBody.substring(0, 256) + '...';
            }
            _this.logger.debug('RPC #{id} {request} -> {response}', {
              id: id,
              request: request.toString(),
              response: responseBody
            });
            return response.extract();
          })["catch"](TimeoutError, function(e) {
            var message;
            message = 'RPC #{id} {request} -> <timed out after {timeout} seconds>';
            _this.logger.warn(message, {
              id: id,
              request: request.toString(),
              timeout: _this.timeout
            });
            throw e;
          });
        };
      })(this));
    };

    AmqpRpcClient.prototype.invokeArray = function(name, args) {
      return this.invoke.apply(this, [name].concat(__slice.call(args)));
    };

    AmqpRpcClient.prototype._initialize = function() {
      if ((this._initializer != null) && !this._initializer.isRejected()) {
        return this._initializer;
      }
      return this._initializer = this.declarationManager.responseQueue().then((function(_this) {
        return function(queue) {
          var handler;
          handler = function(message) {
            return _this._recv(message);
          };
          return _this.channel.consume(queue, handler, {
            noAck: true
          });
        };
      })(this));
    };

    AmqpRpcClient.prototype._send = function(request, id) {
      var payload, promise, timeout;
      payload = this.serialization.serializeRequest(request);
      promise = new Promise((function(_this) {
        return function(resolve, reject) {
          return _this._requests[id] = {
            resolve: resolve,
            reject: reject
          };
        };
      })(this));
      timeout = Math.round(this.timeout * 1000);
      bluebird.join(this.declarationManager.responseQueue(), this.declarationManager.requestQueue(request.name), this.declarationManager.exchange(), (function(_this) {
        return function(responseQueue, requestQueue, exchange) {
          return _this.channel.publish(exchange, request.name, payload, {
            replyTo: responseQueue,
            correlationId: id,
            expiration: timeout
          });
        };
      })(this))["catch"]((function(_this) {
        return function(e) {
          return _this._requests[id].reject(e);
        };
      })(this));
      return promise.timeout(timeout, "RPC request timed out.")["finally"]((function(_this) {
        return function() {
          return delete _this._requests[id];
        };
      })(this));
    };

    AmqpRpcClient.prototype._recv = function(message) {
      var e, id, response, _ref;
      id = (_ref = message.properties.correlationId) != null ? _ref : null;
      if (id == null) {
        return this.logger.warn("Received RPC response with no correlation ID");
      }
      if (this._requests[id] == null) {
        return this.logger.warn("Received RPC response with unknown correlation ID");
      }
      try {
        response = this.serialization.unserializeResponse(message.content);
        return this._requests[id].resolve(response);
      } catch (_error) {
        e = _error;
        return this._requests[id].reject(e);
      }
    };

    return AmqpRpcClient;

  })();

}).call(this);

//# sourceMappingURL=AmqpRpcClient.js.map
