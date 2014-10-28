ExecutionError = require '../error/ExecutionError'
InvalidMessageError = require '../error/InvalidMessageError'
ResponseCode = require './ResponseCode'
UnknownProcedureError = require '../error/UnknownProcedureError'

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
    valueString = if @code.is('SUCCESS') then JSON.stringify(@value) else @value
    @code.key + '(' + valueString + ')'
