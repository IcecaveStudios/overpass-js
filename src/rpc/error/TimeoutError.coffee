module.exports = class TimeoutError extends Error
  constructor: (@timeout) ->
    @message = 'RPC call timed out after ' + @timeout + ' seconds.'
