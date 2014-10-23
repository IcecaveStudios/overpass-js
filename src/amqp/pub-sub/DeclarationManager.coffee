{Promise} = require 'bluebird'

module.exports = class DeclarationManager
  constructor: (channel) ->
    @channel = channel
    @_exchange = undefined

  exchange: ->
    return @_exchange if @_exchange? and not @_exchange.isRejected()

    @_exchange = @channel.assertExchange 'overpass.pubsub', 'topic',
        durable: false
        autoDelete: false
      .then (response) -> response.exchange
