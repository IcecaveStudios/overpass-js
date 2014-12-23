bluebird = require "bluebird"
winston = require "winston"
requireHelper = require "../require-helper"
AmqpFactory = requireHelper "amqp/AmqpFactory"
AmqpPublisher = requireHelper "amqp/pubsub/AmqpPublisher"
AmqpRpcClient = requireHelper "amqp/rpc/AmqpRpcClient"
AmqpSubscriberDriver = requireHelper "amqp/pubsub/AmqpSubscriberDriver"
Subscriber = requireHelper "pubsub/Subscriber"

describe "amqp.AmqpFactory", ->

    beforeEach ->
        @connection = jasmine.createSpyObj "connection", ["createChannel"]
        @logger = {}
        @subject = new AmqpFactory @connection, @logger

    it "stores the supplied dependencies", ->
        expect(@subject.connection).toBe @connection
        expect(@subject.logger).toBe @logger

    it "creates sensible default dependencies", ->
        @subject = new AmqpFactory @connection

        expect(@subject.logger).toBe winston

    describe "when channel creation is successful", ->

        beforeEach ->
            @channel = {}
            @connection.createChannel.andReturn bluebird.resolve @channel

        describe "createPublisher()", ->

            it "creates a new publisher", (done) ->
                @subject.createPublisher()
                .then (result) =>
                    expect(result).toEqual new AmqpPublisher @channel, null, null, @logger
                    done()

        describe "createSubscriber()", ->

            it "creates a new subscriber", (done) ->
                @subject.createSubscriber()
                .then (result) =>
                    expect(result.constructor.name).toBe "Subscriber"
                    expect(result.driver.constructor.name).toBe "AmqpSubscriberDriver"
                    expect(result.driver.channel).toBe @channel
                    expect(result.logger).toBe @logger
                    done()

        describe "createRpcClient()", ->

            it "creates a new RPC client", (done) ->
                @subject.createRpcClient()
                .then (result) =>
                    expect(result).toEqual new AmqpRpcClient @channel, null, null, null, @logger
                    done()

            it "supports custom RPC timeouts", (done) ->
                @subject.createRpcClient(111)
                .then (result) =>
                    expect(result.timeout).toBe 111
                    done()
