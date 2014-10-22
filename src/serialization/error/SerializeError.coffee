module.exports = class SerializeError extends Error
  constructor: ->
    @message = 'Could not serialize payload.'
