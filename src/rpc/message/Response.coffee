ExecutionError = require "../error/ExecutionError"
InvalidMessageError = require "../error/InvalidMessageError"
ResponseCode = require "./ResponseCode"
UnknownProcedureError = require "../error/UnknownProcedureError"

module.exports = class Response
    constructor: (@code, @value) ->

    extract: ->
        return @value if @code is ResponseCode.SUCCESS

        if @code is ResponseCode.INVALID_MESSAGE
            throw new InvalidMessageError @value

        if @code is ResponseCode.UNKNOWN_PROCEDURE
            throw new UnknownProcedureError @value

        throw new ExecutionError @value

    toString: ->
        if @code.is "SUCCESS"
            valueString = JSON.stringify @value
        else
            valueString = @value

        "#{@code.key}(#{valueString})"
