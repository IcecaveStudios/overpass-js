bluebird = require "bluebird"
{EventEmitter} = require "events"
DeclarationManager = require "./DeclarationManager"
JsonSerialization = require "../../serialization/JsonSerialization"

module.exports = class AmqpSubscriberDriver extends EventEmitter

    constructor: (
        @channel
        @declarationManager = new DeclarationManager(@channel)
        @serialization = new JsonSerialization()
    ) ->
        @_count = 0
        @_consumer = bluebird.resolve()
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

    _consume: -> @_consumer = @_consumer.then => @_doConsume()

    _cancelConsume: -> @_consumer = @_consumer.then => @_doCancelConsume()

    _doConsume: ->
        return bluebird.resolve() if @_consumerTag?

        consumer = @declarationManager.queue().then (queue) =>
            @channel.consume queue, @_message, noAck: true

        consumer
            .then (response) =>
                @_consumerTag = response.consumerTag
            .catch (error) =>
                @_consumerTag = null
                throw error

    _doCancelConsume: ->
        return bluebird.resolve() unless @_consumerTag?

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
