SerializeError = require './error/SerializeError'
UnserializeError = require './error/UnserializeError'

module.exports = class JsonSerialization
  serialize: (payload) ->
    type = typeof payload

    return 'null' if type is 'undefined'
    throw new SerializeError() if type not in ['object', 'boolean', 'number', 'string']

    JSON.stringify payload

  unserialize: (buffer) ->
    throw new UnserializeError() if typeof buffer isnt 'string'

    try
      JSON.parse buffer
    catch e
      throw new UnserializeError(e)
