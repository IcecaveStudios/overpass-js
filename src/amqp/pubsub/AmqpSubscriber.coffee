bluebird = require "bluebird"
regexEscape = require "escape-string-regexp"
{EventEmitter} = require "events"
DeclarationManager = require "./DeclarationManager"
JsonSerialization = require "../../serialization/JsonSerialization"

module.exports = class AmqpSubscriber extends EventEmitter

    constructor: (
        @channel
        @declarationManager = new DeclarationManager(@channel)
        @serialization = new JsonSerialization()
        @logger = require "winston"
    ) ->
        @_promises = {}
        @_topicStates = {}
        @_consumer = null
        @_consumerState = "detached"
        @_consumerTag = null
        @_wildcardListeners = {}

        @on "newListener", @_onNewListener
        @on "removeListener", @_onRemoveListener

    subscribe: (topic) ->
        topic = @_normalizeTopic topic

        switch @_state topic
            when "subscribed"
                bluebird.resolve()
            when "subscribing"
                @_promises[topic]
            when "unsubscribed"
                @_setState topic, "subscribing"
                @_promises[topic] = @_doSubscribe topic
            when "unsubscribing"
                @_setState topic, "subscribing"
                @_promises[topic] = @_promises[topic].then =>
                    @_doSubscribe topic

    unsubscribe: (topic) ->
        topic = @_normalizeTopic topic

        switch @_state topic
            when "subscribed"
                @_setState topic, "unsubscribing"
                @_promises[topic] = @_doUnsubscribe topic
            when "subscribing"
                @_setState topic, "unsubscribing"
                @_promises[topic] = @_promises[topic].then =>
                    @_doUnsubscribe topic
            when "unsubscribed"
                bluebird.resolve()
            when "unsubscribing"
                @_promises[topic]

    _doSubscribe: (topic) ->
        @_consume()
        .then => bluebird.join( \
            @declarationManager.queue(),
            @declarationManager.exchange(),
            (queue, exchange) => @channel.bindQueue queue, exchange, topic
        ).then => @_setState(topic, "subscribed")
        .tap => @logger.debug 'Subscribed to topic "{topic}"', topic: topic
        .catch (error) =>
            @_setState topic, "unsubscribed"
            throw error

    _doUnsubscribe: (topic) ->
        bluebird.join( \
            @declarationManager.queue(),
            @declarationManager.exchange(),
            (queue, exchange) => @channel.unbindQueue queue, exchange, topic
        ).then => @_setState topic, "unsubscribed"
        .then =>
            if Object.keys(@_topicStates).length < 1
                @_cancelConsume()
            else return
        .tap => @logger.debug 'Unsubscribed from topic "{topic}"', topic: topic
        .catch (error) =>
            @_setState topic, "subscribed"
            throw error

    _normalizeTopic: (topic) ->
        topic.replace(/\*/g, "#").replace /\?/g, "*"

    _state: (topic) ->
        @_topicStates[topic] ? "unsubscribed"

    _setState: (topic, state) ->
        if state is "unsubscribed"
            delete @_topicStates[topic]
        else
            @_topicStates[topic] = state

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
                handler = (message) =>
                    topic = message.fields.routingKey
                    payloadString = message.content.toString()
                    payload = @serialization.unserialize payloadString
                    @_emit topic, payload
                    @logger.debug 'Received {payload} from topic "{topic}"',
                        topic: topic
                        payload: payloadString
                @channel.consume queue, handler, noAck: true

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

    _emit: (topic, payload) ->
        @emit "message", topic, payload
        @emit "message.#{topic}", topic, payload

        for event, regex of @_wildcardListeners
            if regex.test topic
                @emit event, topic, payload

    _onNewListener: (event, listener) ->
        return if event of @_wildcardListeners

        atoms = event.split "."

        return unless atoms.shift() is "message"

        isPattern = false
        atoms = for atom in atoms
                switch atom
                        when "*"
                                isPattern = true
                                "(.+)"
                        when "?"
                                isPattern = true
                                "([^.]+)"
                        else
                                regexEscape atom

        if isPattern
                pattern = "^#{atoms.join regexEscape "."}$"
                @_wildcardListeners[event] = new RegExp pattern

    _onRemoveListener: (event, listener) ->
        unless EventEmitter.listenerCount @, event
            delete @_wildcardListeners[event]
