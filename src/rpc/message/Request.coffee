module.exports = class Request

    constructor: (@name, @args) ->

    toString: ->
        argsString = @args.map(JSON.stringify).join ", "
        "#{@name}(#{argsString})"
