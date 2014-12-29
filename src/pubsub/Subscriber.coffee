{EventEmitter} = require "events"
bluebird = require "bluebird"
regexEscape = require "escape-string-regexp"
Subscription = require "./Subscription"

class Topic

    constructor: (@name) ->
        @promise = bluebird.resolve()
        @subscriptions = 0

module.exports = class Subscriber extends EventEmitter

    constructor: (@driver, @logger = require "winston") ->
        @_topics = {}
        @_wildcardListeners = {}

        @on "newListener", @_newListener
        @on "removeListener", @_removeListener

        @driver.on "message", @_message

    create: (topic) -> new Subscription @, topic

    subscribe: (topic) ->
        topic = @_topic topic
        topic.promise = topic.promise.then => @_subscribe topic

    unsubscribe: (topic) ->
        topic = @_topic topic
        topic.promise = topic.promise.then => @_unsubscribe topic

    _topic: (name) -> @_topics[name] ?= new Topic name

    _subscribe: (topic) ->
        isSubscribed = topic.subscriptions > 0
        ++topic.subscriptions

        return bluebird.resolve() if isSubscribed

        @driver
        .subscribe topic.name
        .tap => @logger.debug 'Subscribed to topic "{topic}"', topic: topic.name
        .catch (error) =>
            --topic.subscriptions
            throw error

    _unsubscribe: (topic) ->
        return bluebird.resolve() if topic.subscriptions < 1

        --topic.subscriptions

        return bluebird.resolve() if topic.subscriptions > 0

        @driver
        .unsubscribe topic.name
        .tap =>
            @logger.debug 'Unsubscribed from topic "{topic}"', topic: topic.name
        .catch (error) =>
            ++topic.subscriptions
            throw error

    _message: (topic, payload) =>
        @logger.debug 'Received {payload} from topic "{topic}"',
            topic: topic
            payload: JSON.stringify payload

        @emit "message", topic, payload
        @emit "message.#{topic}", topic, payload

        for event, regex of @_wildcardListeners
            if regex.test topic
                @emit event, topic, payload

    _newListener: (event, listener) ->
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

    _removeListener: (event, listener) ->
        unless EventEmitter.listenerCount @, event
            delete @_wildcardListeners[event]
