{EventEmitter} = require "event"
bluebird = require "bluebird"
regexEscape = require "escape-string-regexp"

class Topic

    constructor: (@name) ->
        @promise = bluebird.resolve()
        @state = "unsubscribed"
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
        topic.subscriptions++

        if topic.subscriptions > 1
            return topic.promise

        switch topic.state
            when "subscribed"  then topic.promise
            when "subscribing" then topic.promise
            when "unsubscribed"
                topic.state = "subscribing"
                topic.promise = @_subscribe topic
            when "unsubscribing"
                topic.state = "subscribing"
                topic.promise = topic.promise.then => @_subscribe topic

    unsubscribe: (topic) ->
        topic = @_topic topic

        if topic.subscriptions is 0
            return topic.promise

        topic.subscriptions--

        if topic.subscriptions > 0
            return topic.promise

        switch topic.state
            when "unsubscribed"  then topic.promise
            when "unsubscribing" then topic.promise
            when "subscribed"
                topic.state = "unsubscribing"
                topic.promise = @_unsubscribe topic
            when "subscribing"
                topic.state = "unsubscribing"
                topic.promise = topic.promise.then => @_unsubscribe topic

    _topic: (name) -> @_topics[name] ?= new Topic name

    _subscribe: (topic) ->
        @driver
        .subscribe topic.name
        .then => topic.state = "subscribed"
        .tap => @logger.debug 'Subscribed to topic "{topic}"', topic: topic.name
        .catch (error) =>
            @topic.state = "unsubscribed"
            throw error

    _unsubscribe: (topic) ->
        @driver
        .unsubscribe topic.name
        .then => topic.state = "unsubscribed"
        .tap => @logger.debug 'Unsubscribed from topic "{topic}"', topic: topic
        .catch (error) =>
            @topic.state = "subscribed"
            throw error

    _message: (topic, payload) =>
        @logger.debug 'Received {payload} from topic "{topic}"',
            topic: topic
            payload: payloadString

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
        delete @_wildcardListeners[event] unless EventEmitter.listenerCount @, event
