bluebird = require 'bluebird'

module.exports = class DeclarationManager
  constructor: (@channel) ->
    @_exchange = null
    @_queue = null

  exchange: ->
    return @_exchange if @_exchange? and not @_exchange.isRejected()

    @_exchange = bluebird.resolve \
      @channel.assertExchange 'overpass/pubsub', 'topic',
        autoDelete: false
        durable: false
      .then (response) -> response.exchange

  queue: ->
    return @_queue if @_queue? and not @_queue.isRejected()

    @_queue = bluebird.resolve \
      @channel.assertQueue null,
        exclusive: true
        autoDelete: true
        durable: false
      .then (response) -> response.queue
