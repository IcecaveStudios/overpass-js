{EventEmitter} = require "events"
bluebird = require "bluebird"

module.exports = class Subscription extends EventEmitter

    constructor: (@subscriber, @topic) ->
        @_isSubscribed = false
        @_promise = bluebird.resolve()

    enable: -> @_promise = @_promise.then => @_subscribe()

    disable: -> @_promise = @_promise.then => @_unsubscribe()

    _subscribe: ->
        return bluebird.resolve() if @_isSubscribed

        @_isSubscribed = true

        @subscriber.subscribe(@topic)
        .then =>
            @subscriber.on "message.#{@topic}", @_message
        .catch (error) =>
            @_isSubscribed = false
            throw error

    _unsubscribe: ->
        return bluebird.resolve() unless @_isSubscribed

        @_isSubscribed = false

        @subscriber.unsubscribe(@topic)
        .then =>
            @subscriber.removeListener "message.#{@topic}", @_message
        .catch (error) =>
            @_isSubscribed = true
            throw error

    _message: (topic, payload) =>
        @emit "message", topic, payload
