bluebird = require 'bluebird'

module.exports = class DeclarationManager
  constructor: (@channel) ->
    @_exchange = null
    @_requestQueues = {}
    @_responseQueue = null

  exchange: ->
    return @_exchange if @_exchange? and not @_exchange.isRejected()

    @_exchange = bluebird.resolve \
      @channel.assertExchange 'overpass/rpc', 'direct',
        autoDelete: false
        durable: false
      .then (response) -> response.exchange

  requestQueue: (procedureName) ->
    if @_requestQueues[procedureName]?
      if not @_requestQueues[procedureName].isRejected()
        return @_requestQueues[procedureName]

    @_requestQueues[procedureName] = bluebird.resolve \
      @channel.assertQueue 'overpass/rpc/' + procedureName,
        exclusive: false
        autoDelete: false
        durable: false
      .then (response) -> response.queue

  responseQueue: () ->
    if @_responseQueue? and not @_responseQueue.isRejected()
      return @_responseQueue

    @_responseQueue = bluebird.resolve \
      @channel.assertQueue null,
        exclusive: true
        autoDelete: true
        durable: false
      .then (response) -> response.queue
