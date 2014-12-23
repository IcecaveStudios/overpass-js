{EventEmitter} = require "event"
bluebird = require "bluebird"

module.exports = class Subscription extends EventEmitter

    constructor: (@subscriber, @topic) ->
        @_state = "unsubscribed"
        @_promise = null

    enable: ->
        switch @_state
            when "subscribed"
                bluebird.resolve()
            when "subscribing"
                @_promise
            when "unsubscribed"
                @_state = "subscribing"
                @_promise = @_subscribe()
            when "unsubscribing"
                @_state = "subscribing"
                @_promise = @_promise.then => @_subscribe()

    disable: ->
        switch @_state
            when "subscribed"
                @_state = "unsubscribing"
                @_promise = @_unsubscribe()
            when "subscribing"
                @_state = "unsubscribing"
                @_promise = @_promise.then => @_unsubscribe()
            when "unsubscribed"
                bluebird.resolve()
            when "unsubscribing"
                @_promise

    _message: (topic, payload) =>
        @emit "message", topic, payload

    _subscribe: ->
        @subscriber.on "message.#{@topic}", @_message
        @subscriber.subscribe @topic
        .tap => @emit "subscribe"

    _unsubscribe: ->
        @subscriber.removeListener "message.#{@topic}", @_message
        @subscriber.unsubscribe @topic
        .tap => @emit "unsubscribe"
