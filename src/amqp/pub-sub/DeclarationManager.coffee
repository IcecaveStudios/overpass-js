module.exports = class DeclarationManager
  constructor: (channel) ->
    @channel = channel

  exchange: ->
    p = @channel.assertExchange 'overpass.pubsub', 'topic',
      durable: false
      autoDelete: false

    p.then (response) ->
      return response.exchange

