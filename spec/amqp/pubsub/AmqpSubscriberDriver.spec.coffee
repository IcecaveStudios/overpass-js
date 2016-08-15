bluebird = require "bluebird"
requireHelper = require "../../require-helper"
AmqpSubscriberDriver = requireHelper "amqp/pubsub/AmqpSubscriberDriver"
DeclarationManager = requireHelper "amqp/pubsub/DeclarationManager"
JsonSerialization = requireHelper "serialization/JsonSerialization"

describe "amqp.pubsub.AmqpSubscriberDriver", ->

    beforeEach ->
        @channel = jasmine.createSpyObj "channel", ["bindQueue", "unbindQueue", "consume", "cancel"]
        @declarationManager = jasmine.createSpyObj "declarationManager", ["queue", "exchange"]
        @serialization = new JsonSerialization()
        @subject = new AmqpSubscriberDriver @channel, @declarationManager, @serialization

        @error = new Error "Error message."
        @consumeCallback = null

        @declarationManager.queue.andCallFake -> bluebird.resolve "queue-name"
        @declarationManager.exchange.andCallFake -> bluebird.resolve "exchange-name"
        @channel.consume.andCallFake (queue, callback) =>
            @consumeCallback = callback
            bluebird.resolve consumerTag: "consumer-tag"
        @channel.cancel.andCallFake -> bluebird.resolve()

    it "stores the supplied dependencies", ->
        expect(@subject.channel).toBe @channel
        expect(@subject.declarationManager).toBe @declarationManager
        expect(@subject.serialization).toBe @serialization

    it "creates sensible default dependencies", ->
        @subject = new AmqpSubscriberDriver @channel

        expect(@subject.declarationManager).toEqual new DeclarationManager @channel
        expect(@subject.serialization).toEqual new JsonSerialization

    describe "subscribe()", ->

        it "binds correctly", (done) ->
            bluebird.join \
                @subject.subscribe("topic.*.a"),
                @subject.subscribe("topic.?.b"),
                =>
                    expect(@channel.bindQueue).toHaveBeenCalledWith "queue-name", "exchange-name", "topic.#.a"
                    expect(@channel.bindQueue).toHaveBeenCalledWith "queue-name", "exchange-name", "topic.*.b"
                    done()

        it "propagates queue creation errors", (done) ->
            @declarationManager.queue.andCallFake => bluebird.reject @error

            @subject.subscribe("topic-name").catch (actual) =>
                expect(actual).toBe @error
                expect(@channel.bindQueue.calls.length).toBe 0
                done()

        it "propagates exchange creation errors", (done) ->
            @declarationManager.exchange.andCallFake => bluebird.reject @error

            @subject.subscribe("topic-name").catch (actual) =>
                expect(actual).toBe @error
                expect(@channel.bindQueue.calls.length).toBe 0
                done()

        it "propagates binding errors", (done) ->
            @channel.bindQueue.andCallFake => bluebird.reject @error

            @subject.subscribe("topic-name").catch (actual) =>
                expect(actual).toBe @error
                done()

        it "starts consuming when subscriptions are added concurrently", (done) ->
            @subject.subscribe "topic-a"

            @subject.subscribe("topic-b").then =>
                expect(@channel.consume).toHaveBeenCalledWith "queue-name", jasmine.any(Function), noAck: true
                expect(@channel.consume.calls.length).toBe 1
                expect(@subject._consumerTag).toBe "consumer-tag"
                done()

        it "starts consuming when subscriptions are added sequentially", (done) ->
            @subject.subscribe("topic-a")
            .then =>
                @subject.subscribe "topic-b"
            .then =>
                expect(@channel.consume).toHaveBeenCalledWith "queue-name", jasmine.any(Function), noAck: true
                expect(@channel.consume.calls.length).toBe 1
                expect(@subject._consumerTag).toBe "consumer-tag"
                done()

    describe "unsubscribe()", ->

        it "unbinds correctly", (done) ->
            bluebird.join \
                @subject.subscribe("topic.*.a"),
                @subject.unsubscribe("topic.*.a"),
                @subject.subscribe("topic.?.b"),
                @subject.unsubscribe("topic.?.b"),
                =>
                    expect(@channel.unbindQueue).toHaveBeenCalledWith "queue-name", "exchange-name", "topic.#.a"
                    expect(@channel.unbindQueue).toHaveBeenCalledWith "queue-name", "exchange-name", "topic.*.b"
                    done()

        it "propagates unbinding errors", (done) ->
            @channel.unbindQueue.andCallFake => bluebird.reject @error

            @subject.subscribe("topic-name")
            .then => @subject.unsubscribe("topic-name")
            .catch (actual) =>
                expect(actual).toBe @error
                expect(@channel.unbindQueue.calls.length).toBe 1
                done()

        it "stops consuming when all subscriptions are removed concurrently", (done) ->
            @subject.subscribe "topic-a"
            @subject.subscribe "topic-b"
            @subject.unsubscribe "topic-a"

            @subject.unsubscribe("topic-b").then =>
                expect(@channel.consume).toHaveBeenCalledWith "queue-name", jasmine.any(Function), noAck: true
                expect(@channel.consume.calls.length).toBe 1
                expect(@channel.cancel).toHaveBeenCalledWith "consumer-tag"
                expect(@channel.cancel.calls.length).toBe 1
                expect(@subject._consumerTag).toBeNull()
                done()

        it "stops consuming when all subscriptions are removed sequentially", (done) ->
            @subject.subscribe("topic-a")
            .then => @subject.subscribe("topic-b")
            .then => @subject.unsubscribe("topic-a")
            .then => @subject.unsubscribe("topic-b")
            .then =>
                expect(@channel.consume).toHaveBeenCalledWith "queue-name", jasmine.any(Function), noAck: true
                expect(@channel.consume.calls.length).toBe 1
                expect(@channel.cancel).toHaveBeenCalledWith "consumer-tag"
                expect(@channel.cancel.calls.length).toBe 1
                expect(@subject._consumerTag).toBeNull()
                done()

    describe "_consume()", ->

        it "emits generic message events", (done) ->
            @subject.on "message", (type, payload) ->
                expect(type).toBe "routing-key"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._consume().then =>
                @consumeCallback
                    fields: routingKey: "routing-key"
                    content: new Buffer '{"a":"b","c":"d"}'

        it "can consume after a pending cancel", (done) ->
            @subject._consume()
            @subject._cancelConsume()

            @subject._consume().then =>
                expect(@channel.consume).toHaveBeenCalledWith "queue-name", jasmine.any(Function), noAck: true
                expect(@channel.consume.calls.length).toBe 2
                expect(@channel.cancel).toHaveBeenCalledWith "consumer-tag"
                expect(@channel.cancel.calls.length).toBe 1
                expect(@subject._consumerTag).toBe "consumer-tag"
                done()

    describe "_cancelConsume()", ->

        it "correctly handles cancellation when already detatched", (done) ->
            @subject._cancelConsume().then =>
                expect(@channel.consume.calls.length).toBe 0
                expect(@channel.cancel.calls.length).toBe 0
                expect(@subject._consumerTag).toBeNull()
                done()

        it "correctly handles a failure", (done) ->
            @channel.cancel.andCallFake => bluebird.reject @error

            @subject._consume()
            .then => @subject._cancelConsume()
            .catch (actual) =>
                expect(actual).toBe @error
                expect(@subject._consumerTag).toBe "consumer-tag"
                done()
