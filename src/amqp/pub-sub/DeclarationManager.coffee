{Promise} = require 'bluebird'

module.exports = class DeclarationManager
  constructor: (@channel) ->
    @_exchange = undefined
    @_queue = undefined

  exchange: ->
    return @_exchange if @_exchange? and not @_exchange.isRejected()

    @_exchange = @channel.assertExchange 'overpass.pubsub', 'topic',
        durable: false
        autoDelete: false
      .then (response) -> response.exchange

  queue: ->
    return @_queue if @_queue? and not @_queue.isRejected()

    @_queue = @channel.assertQueue null,
        durable: false
        exclusive: true
      .then (response) -> response.queue
