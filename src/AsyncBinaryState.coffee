bluebird = require "bluebird"

module.exports = class AsyncBinaryState

    constructor: (@isOn = false) -> @_promise = bluebird.resolve()

    setOn: (handler) => @set true, handler

    setOff: (handler) => @set false, handler

    set: (isOn, handler) =>
        callback = => @_set isOn, handler
        @_promise = @_promise.then callback, callback

    _set: (isOn, handler) =>
        return bluebird.resolve() if isOn is @isOn

        @isOn = isOn

        promise = bluebird.resolve handler?()

        promise.catch => @isOn = not @isOn

        promise
