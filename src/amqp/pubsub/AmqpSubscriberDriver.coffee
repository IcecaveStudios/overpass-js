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
        @_consumer = null
        @_consumerState = "detached"
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
        switch @_consumerState
            when "consuming"
                bluebird.resolve()
            when "attaching"
                @_consumer
            when "detached"
                @_consumerState = "attaching"
                @_consumer = @_doConsume()
            when "cancelling"
                @_consumerState = "attaching"
                @_consumer = @_consumer.then => @_doConsume()

    _cancelConsume: ->
        switch @_consumerState
            when "consuming"
                @_consumerState = "cancelling"
                @_consumer = @_doCancelConsume()
            when "attaching"
                @_consumerState = "cancelling"
                @_consumer = @_consumer.then => @_doCancelConsume()
            when "detached"
                bluebird.resolve()
            when "cancelling"
                @_consumer

    _doConsume: ->
        consumer = @declarationManager.queue().then (queue) =>
                @channel.consume queue, @_message, noAck: true

        consumer
            .then (response) =>
                @_consumerState = "consuming"
                @_consumerTag = response.consumerTag
            .catch (error) =>
                @_consumerState = "detached"
                throw error

    _doCancelConsume: ->
        cancel = @channel.cancel @_consumerTag
        cancel
            .then =>
                @_consumerState = "detached"
                @_consumerTag = null
            .catch (error) =>
                @_consumerState = "consuming"
                throw error

    _message: (message) =>
        topic = message.fields.routingKey

        payloadString = message.content.toString()
        payload = @serialization.unserialize payloadString

        @emit "message", topic, payload
