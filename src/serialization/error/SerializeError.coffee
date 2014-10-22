module.exports = class SerializeError extends Error
  constructor: (cause) ->
    @message = 'Could not serialize payload.'
    @cause = cause
