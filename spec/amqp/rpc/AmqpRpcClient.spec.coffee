bluebird = require "bluebird"
winston = require "winston"
{TimeoutError} = require "bluebird"
requireHelper = require "../../require-helper"
AmqpRpcClient = requireHelper "amqp/rpc/AmqpRpcClient"
DeclarationManager = requireHelper "amqp/rpc/DeclarationManager"
ExecutionError = requireHelper "rpc/error/ExecutionError"
InvalidMessageError = requireHelper "rpc/error/InvalidMessageError"
MessageSerialization = requireHelper "rpc/message/serialization/MessageSerialization"

describe "amqp.rpc.AmqpRpcClient", ->

    beforeEach ->
        @channel = jasmine.createSpyObj "channel", ["consume", "publish"]
        @timeout = 10
        @declarationManager = jasmine.createSpyObj "declarationManager", ["exchange", "requestQueue", "responseQueue"]
        @serialization = new MessageSerialization()
        @logger = jasmine.createSpyObj "logger", ["warn", "debug"]
        @subject = new AmqpRpcClient @channel, @timeout, @declarationManager, @serialization, @logger

        @error = new Error "Error message."
        @consumeCallback = null
        @publishedPayload = null
        @publishedId = null

        @declarationManager.exchange.andCallFake -> bluebird.resolve "exchange-name"
        @declarationManager.responseQueue.andCallFake -> bluebird.resolve "queue-name"
        @channel.consume.andCallFake (queue, callback) =>
            @consumeCallback = callback
            bluebird.resolve()
        @channel.publish.andCallFake (exchange, topic, payload, options) =>
            @publishedPayload = payload
            @publishedId = options.correlationId
            @consumeCallback
                properties:
                    correlationId: options.correlationId
                content: new Buffer '[0,["a",{"b":"c"},["d","e"]]]'
            bluebird.resolve()

    it "stores the supplied dependencies", ->
        expect(@subject.channel).toBe @channel
        expect(@subject.timeout).toBe @timeout
        expect(@subject.declarationManager).toBe @declarationManager
        expect(@subject.serialization).toBe @serialization
        expect(@subject.logger).toBe @logger

    it "creates sensible default dependencies", ->
        @subject = new AmqpRpcClient @channel

        expect(@subject.timeout).toBe 10
        expect(@subject.declarationManager).toEqual new DeclarationManager @channel
        expect(@subject.serialization).toEqual new MessageSerialization
        expect(@subject.logger).toBe winston

    describe "invoke()", ->

        describe "with a success result", ->
            it "returns the result when arguments are passed", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .then (result) =>
                    expect(result).toEqual ["a", b: "c", ["d", "e"]]
                    expect(@declarationManager.requestQueue).toHaveBeenCalledWith "procedureA"
                    expect(@channel.publish).toHaveBeenCalledWith "exchange-name", "procedureA", jasmine.any(Buffer),
                        replyTo: "queue-name"
                        correlationId: @publishedId
                        expiration: @timeout * 1000
                        content_encoding: 'gzip'
                    done()

            it "returns the result when no arguments are passed", (done) ->
                @subject.invoke("procedureA")
                .then (result) =>
                    expect(result).toEqual ["a", b: "c", ["d", "e"]]
                    expect(@declarationManager.requestQueue).toHaveBeenCalledWith "procedureA"
                    expect(@channel.publish).toHaveBeenCalledWith "exchange-name", "procedureA", jasmine.any(Buffer),
                        replyTo: "queue-name"
                        correlationId: @publishedId
                        expiration: @timeout * 1000
                        content_encoding: 'gzip'
                    done()

            it "can handle concurrent requests on first initialization", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                @subject.invoke("procedureA", "a", "b", c: "d")
                .then (result) =>
                    expect(result).toEqual ["a", b: "c", ["d", "e"]]
                    done()

            it "logs the details", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .then =>
                    expect(@logger.debug).toHaveBeenCalledWith 'RPC #{id} {request}',
                        id: @publishedId,
                        request: 'procedureA("a", "b", {"c":"d"})'
                    expect(@logger.debug).toHaveBeenCalledWith 'RPC #{id} {request} -> {response}',
                        id: @publishedId,
                        request: 'procedureA("a", "b", {"c":"d"})'
                        response: 'SUCCESS(["a",{"b":"c"},["d","e"]])'
                    done()

        describe "with a failure result", ->

            beforeEach ->
                @channel.publish.andCallFake (exchange, topic, payload, options) =>
                    @publishedPayload = payload
                    @publishedId = options.correlationId
                    @consumeCallback
                        properties:
                            correlationId: options.correlationId
                        content: new Buffer '[10,"You done goofed."]'
                    bluebird.resolve()

            it "throws the error", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .catch (error) =>
                    expect(error).toEqual new ExecutionError "You done goofed."
                    done()

            it "logs the details", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .catch (error) =>
                    expect(@logger.debug).toHaveBeenCalledWith 'RPC #{id} {request}',
                        id: @publishedId,
                        request: 'procedureA("a", "b", {"c":"d"})'
                    expect(@logger.debug).toHaveBeenCalledWith 'RPC #{id} {request} -> {response}',
                        id: @publishedId,
                        request: 'procedureA("a", "b", {"c":"d"})'
                        response: "ERROR(You done goofed.)"
                    done()

        describe "with a request timeout", ->

            beforeEach ->
                @timeout = .001
                @subject = new AmqpRpcClient @channel, @timeout, @declarationManager, @serialization, @logger

                @channel.publish.andCallFake (exchange, topic, payload, options) =>
                    @publishedPayload = payload
                    @publishedId = options.correlationId
                    bluebird.resolve()

            it "throws a timeout error", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .catch (error) =>
                    expect(error).toEqual new TimeoutError "RPC request timed out."
                    done()

            it "logs the details", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .catch (error) =>
                    expect(@logger.debug).toHaveBeenCalledWith 'RPC #{id} {request}',
                        id: @publishedId,
                        request: 'procedureA("a", "b", {"c":"d"})'
                    expect(@logger.warn).toHaveBeenCalledWith \
                        'RPC #{id} {request} -> <timed out after {timeout} seconds>',
                        id: @publishedId
                        request: 'procedureA("a", "b", {"c":"d"})'
                        timeout: @timeout
                    done()

        describe "with a request queue creation error", ->

            beforeEach ->
                @declarationManager.requestQueue.andCallFake => bluebird.reject @error

            it "propagates the error", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .catch (error) =>
                    expect(error).toBe @error
                    done()

        describe "with a response queue creation error", ->

            beforeEach ->
                @declarationManager.responseQueue.andCallFake => bluebird.reject @error

            it "propagates the error", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .catch (error) =>
                    expect(error).toBe @error
                    done()

        describe "with an exchange creation error", ->

            beforeEach ->
                @declarationManager.exchange.andCallFake => bluebird.reject @error

            it "propagates the error", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .catch (error) =>
                    expect(error).toBe @error
                    done()

        describe "with a response containing an unknown correlation ID", ->

            beforeEach (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d").then -> done()

            it "logs the details", ->
                @consumeCallback
                    properties:
                        correlationId: "111"
                    content: new Buffer '[0,["a",{"b":"c"},["d","e"]]]'

                expect(@logger.warn).toHaveBeenCalledWith "Received RPC response with unknown correlation ID"

        describe "with a response containing no correlation ID", ->

            beforeEach (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d").then -> done()

            it "logs the details", ->
                @consumeCallback
                    properties: {}
                    content: new Buffer '[0,["a",{"b":"c"},["d","e"]]]'

                expect(@logger.warn).toHaveBeenCalledWith "Received RPC response with no correlation ID"

        describe "with an invalid JSON response", ->

            beforeEach ->
                @channel.publish.andCallFake (exchange, topic, payload, options) =>
                    @publishedPayload = payload
                    @publishedId = options.correlationId
                    @consumeCallback
                        properties:
                            correlationId: options.correlationId
                        content: new Buffer "1337h4x"
                    bluebird.resolve()

            it "throws an unserialization error", (done) ->
                @subject.invoke("procedureA", "a", "b", c: "d")
                .catch (error) =>
                    expect(error).toEqual new InvalidMessageError "Response payload is invalid."
                    done()

        it "can invoke after an initial error", (done) ->
            @declarationManager.responseQueue.andCallFake => bluebird.reject @error
            @subject.invoke("procedureA", "a", "b", c: "d")
            .catch(->)
            .then =>
                @declarationManager.responseQueue.andCallFake -> bluebird.resolve "queue-name"
                @subject.invoke("procedureA", "a", "b", c: "d")
                .then (result) =>
                    expect(result).toEqual ["a", b: "c", ["d", "e"]]
                    done()

    describe "invokeArray()", ->

        it "proxies calls to invoke()", (done) ->
            @subject.invokeArray("procedureA", ["a", "b", c: "d"])
            .then (result) =>
                expect(result).toEqual ["a", b: "c", ["d", "e"]]
                expect(@declarationManager.requestQueue).toHaveBeenCalledWith "procedureA"
                expect(@channel.publish).toHaveBeenCalledWith "exchange-name", "procedureA", jasmine.any(Buffer),
                    replyTo: "queue-name"
                    correlationId: @publishedId
                    expiration: @timeout * 1000
                    content_encoding: 'gzip'
                done()
