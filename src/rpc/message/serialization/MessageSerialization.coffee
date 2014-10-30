InvalidMessageError = require '../../error/InvalidMessageError'
JsonSerialization = require '../../../serialization/JsonSerialization'
Response = require '../Response'
ResponseCode = require '../ResponseCode'

module.exports = class MessageSerialization
  constructor: (@serialization = new JsonSerialization()) ->

  serializeRequest: (request) ->
    @serialization.serialize [request.name, request.arguments]

  unserializeResponse: (buffer) ->
    try
      payload = @serialization.unserialize buffer
    catch e
      throw new InvalidMessageError 'Response payload is invalid.'

    if payload not instanceof Array or payload.length isnt 2
      throw new InvalidMessageError 'Response payload must be a 2-tuple.'

    [code, value] = payload

    if not code = ResponseCode.get(code)
      throw new InvalidMessageError 'Response code is unrecognised.'

    if code isnt ResponseCode.SUCCESS and typeof value isnt 'string'
      throw new InvalidMessageError 'Response error message must be a string.'

    new Response code, value
