module.exports = class AmqpFactory

    constructor: (
        @connection
        @rpcTimeout = 3
        @logger = require "winston"
    ) ->

    createPublisher: ->
        @connection
            .createChannel()
            .then (channel) => new Publisher channel, @logger

    createSubscriber: ->
        @connection
            .createChannel()
            .then (channel) =>
                driver = new AmqpSubscriberDriver channel
                new Subscriber driver, @logger

    createRpcClient: ->
        @connection
            .createChannel()
            .then (channel) => new AmqpRpcClient channel, @rpcTimeout, null, null, @logger
