{EventEmitter} = require "events"
bluebird = require "bluebird"
AsyncBinaryState = require "../AsyncBinaryState"

module.exports = class Subscription extends EventEmitter

    constructor: (@subscriber, @topic) ->
        @_state = new AsyncBinaryState()

    enable: ->
        @_state.setOn =>
            @subscriber.subscribe(@topic)
            .then =>
                @subscriber.on "message.#{@topic}", @_message

    disable: ->
        @_state.setOff =>
            @subscriber.unsubscribe(@topic)
            .then =>
                @subscriber.removeListener "message.#{@topic}", @_message

    _message: (topic, payload) => @emit "message", topic, payload
