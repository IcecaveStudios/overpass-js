SerializeError = require './error/SerializeError'
UnserializeError = require './error/UnserializeError'

module.exports = class JsonSerialization
  serialize: (payload) ->
    throw new SerializeError() if typeof payload not in ['object', 'array'] or
      payload is null

    JSON.stringify payload

  unserialize: (buffer) ->
    throw new UnserializeError() if typeof buffer isnt 'string'

    try
      payload = JSON.parse buffer
    catch e
      throw new UnserializeError(e)

    throw new UnserializeError() if typeof payload not in ['object', 'array'] or
      payload is null

    payload
