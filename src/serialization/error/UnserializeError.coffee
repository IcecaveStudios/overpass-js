module.exports = class UnserializeError extends Error
  constructor: (cause) ->
    @message = 'Could not unserialize payload.'
    @cause = cause
