bluebird = require "bluebird"
{Promise} = require "bluebird"
{TimeoutError} = require "bluebird"
DeclarationManager = require "./DeclarationManager"
GzipEncoding = require "../../serialization/GzipEncoding"
MessageSerialization = require "../../rpc/message/serialization/MessageSerialization"
Request = require "../../rpc/message/Request"
ResponseCode = require "../../rpc/message/ResponseCode"

module.exports = class AmqpRpcClient

    constructor: (
        @channel
        @timeout = 10
        @declarationManager = new DeclarationManager(@channel)
        @serialization = new MessageSerialization()
        @logger = require "winston"
        @encoding = new GzipEncoding()
    ) ->
        @_initializer = null
        @_requests = {}
        @_id = 0

    invoke: (name, args...) ->
        @_initialize().then =>
            id = (++@_id).toString()
            request = new Request name, args

            @logger.debug 'RPC #{id} {request}',
                id: id
                request: request.toString()

            @_send(request, id)
            .then (response) =>
                responseBody = response.toString()
                isSuccess = response.code is ResponseCode.SUCCESS

                if isSuccess and responseBody.length > 256
                    responseBody = responseBody.substring(0, 256) + '...'

                @logger.debug 'RPC #{id} {request} -> {response}',
                    id: id
                    request: request.toString()
                    response: responseBody
                response.extract()
            .catch TimeoutError, (e) =>
                message =
                    'RPC #{id} {request} -> <timed out after {timeout} seconds>'
                @logger.warn message,
                    id: id
                    request: request.toString()
                    timeout: @timeout
                throw e

    invokeArray: (name, args) -> @invoke name, args...

    _initialize: ->
        if @_initializer? and not @_initializer.isRejected()
            return @_initializer

        @_initializer = @declarationManager.responseQueue().then (queue) =>
            handler = (message) => @_recv message
            @channel.consume queue, handler, noAck: true

    _send: (request, id) ->
        serializedRequest = @serialization.serializeRequest request

        promise = new Promise (resolve, reject) =>
            @_requests[id] = {resolve, reject}

        timeout = Math.round @timeout * 1000

        bluebird.join \
            @declarationManager.responseQueue(),
            @declarationManager.requestQueue(request.name),
            @declarationManager.exchange(),
            @encoding.encode(null, serializedRequest),
            (responseQueue, requestQueue, exchange, [payload, encoding]) =>
                properties =
                    replyTo: responseQueue
                    correlationId: id
                    expiration: timeout
                if encoding?
                    properties.content_encoding = encoding
                @channel.publish exchange, request.name, payload, properties

        .catch (e) => @_requests[id].reject e

        promise
            .timeout timeout, "RPC request timed out."
            .finally => delete @_requests[id]

    _recv: (message) ->
        id = message.properties.correlationId ? null

        if not id?
            return @logger.warn "Received RPC response with no correlation ID"

        if not @_requests[id]?
            return @logger.warn \
                "Received RPC response with unknown correlation ID"

        return new Promise (resolve, reject) =>
            if not message.content_encoding?
                return resolve @_deserialize id, message.content

            return @encoding.decode(message.content_encoding, message.content).then (content) =>
                resolve @_deserialize(id, content)

    _deserialize: (id, content) ->
        try
            response = @serialization.unserializeResponse(content)
            @_requests[id].resolve response
        catch e
            @_requests[id].reject e
