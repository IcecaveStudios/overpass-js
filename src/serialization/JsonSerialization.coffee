SerializeError = require './error/SerializeError'

module.exports = class JsonSerialization
  serialize: (payload) ->
    type = typeof payload

    return 'null' if type is 'undefined'
    throw new SerializeError() if type not in ['object', 'boolean', 'number', 'string']

    JSON.stringify payload
