bluebird = require "bluebird"
{EventEmitter} = require "events"
DeclarationManager = require "./DeclarationManager"
JsonSerialization = require "../../serialization/JsonSerialization"
AsyncBinaryState = require "../../AsyncBinaryState"

module.exports = class AmqpSubscriberDriver extends EventEmitter

    constructor: (
        @channel
        @declarationManager = new DeclarationManager(@channel)
        @serialization = new JsonSerialization()
    ) ->
        @_count = 0
        @_consumeState = new AsyncBinaryState()
        @_consumerTag = null

    subscribe: (topic) ->
        topic = @_normalizeTopic topic

        ++@_count

        @_consume()
        .then => bluebird.join(
            @declarationManager.queue(),
            @declarationManager.exchange(),
            (queue, exchange) => @channel.bindQueue queue, exchange, topic
        )
        .catch (error) =>
            --@_count
            throw error

    unsubscribe: (topic) ->
        topic = @_normalizeTopic topic

        --@_count

        bluebird.join(
            @declarationManager.queue(),
            @declarationManager.exchange(),
            (queue, exchange) => @channel.unbindQueue queue, exchange, topic
        )
        .catch (error) =>
            ++@_count
            throw error
        .then =>
            @_cancelConsume() unless @_count

    _normalizeTopic: (topic) ->
        topic.replace(/\*/g, "#").replace /\?/g, "*"

    _consume: ->
        @_consumeState.setOn =>
            consumer = @declarationManager.queue().then (queue) =>
                @channel.consume queue, @_message, noAck: true

            consumer
                .then (response) =>
                    @_consumerTag = response.consumerTag
                .catch (error) =>
                    @_consumerTag = null
                    throw error

    _cancelConsume: ->
        @_consumeState.setOff =>
            consumerTag = @_consumerTag

            cancel = @channel.cancel @_consumerTag
            cancel
                .then =>
                    @_consumerTag = null
                .catch (error) =>
                    @_consumerTag = consumerTag
                    throw error

    _message: (message) =>
        topic = message.fields.routingKey

        payloadString = message.content.toString()
        payload = @serialization.unserialize payloadString

        @emit "message", topic, payload
