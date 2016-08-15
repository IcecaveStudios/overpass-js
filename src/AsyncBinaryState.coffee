bluebird = require "bluebird"

module.exports = class AsyncBinaryState

    constructor: (@isOn = false) ->
        @_targetState = @isOn
        @_promise = bluebird.resolve()

    setOn: (handler) => @set true, handler

    setOff: (handler) => @set false, handler

    set: (isOn, handler) =>
        callback = => @_set isOn, handler
        @_promise = @_promise.then callback, callback

    _set: (isOn, handler) =>
        return bluebird.resolve() if isOn is @_targetState

        @_targetState = isOn

        if handler?
            method = bluebird.method -> handler()
        else
            method = -> bluebird.resolve()

        method()
        .tap => @isOn = isOn
        .catch (error) =>
            @_targetState = not isOn

            throw error
