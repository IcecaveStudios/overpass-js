module.exports = class Request
  constructor: (@name, @arguments) ->

  toString: ->
    @name + '(' + @arguments.map(JSON.stringify).join(', ') + ')'
