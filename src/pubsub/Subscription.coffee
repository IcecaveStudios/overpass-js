AsyncBinaryState = require "../AsyncBinaryState"
bluebird = require "bluebird"
regexEscape = require "escape-string-regexp"
{EventEmitter} = require "events"

module.exports = class Subscription extends EventEmitter

    constructor: (@subscriber, @topic) ->
        @_state = new AsyncBinaryState()

        atoms = for atom in @topic.split "."
            switch atom
                when "*" then "(.+)"
                when "?" then  "([^.]+)"
                else regexEscape atom

        @_pattern = new RegExp "^#{atoms.join regexEscape "."}$"

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

    match: (topic) -> @_pattern.test topic

    _message: (topic, payload) => @emit "message", topic, payload
