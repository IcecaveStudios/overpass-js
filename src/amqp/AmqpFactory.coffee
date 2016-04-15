AmqpPublisher = require "./pubsub/AmqpPublisher"
AmqpRpcClient = require "./rpc/AmqpRpcClient"
AmqpSubscriberDriver = require "./pubsub/AmqpSubscriberDriver"
Subscriber = require "../pubsub/Subscriber"

module.exports = class AmqpFactory

    constructor: (@connection, @encoder, @logger = require "winston") ->

    createPublisher: ->
        @connection.createChannel()
        .then (channel) => new AmqpPublisher channel, null, null, @logger

    createSubscriber: ->
        @connection.createChannel()
        .then (channel) =>
            new Subscriber new AmqpSubscriberDriver(channel), @logger

    createRpcClient: (timeout = null) ->
        @connection.createChannel()
        .then (channel) =>
            new AmqpRpcClient channel, timeout, null, null, @logger, @encoder
