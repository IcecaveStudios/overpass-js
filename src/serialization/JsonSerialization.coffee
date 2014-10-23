module.exports = class JsonSerialization
  serialize: (payload) ->
    if typeof payload not in ['object', 'array'] or payload is null
      throw new Error 'Payload must be an object or an array.'

    JSON.stringify payload

  unserialize: (buffer) ->
    throw new Error('Could not unserialize payload.') if typeof buffer isnt 'string'

    payload = JSON.parse buffer

    if typeof payload not in ['object', 'array'] or payload is null
      throw new Error('Payload must be an object or an array.')

    payload
