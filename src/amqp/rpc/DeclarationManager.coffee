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

    queue = 'overpass/rpc/' + procedureName

    @_requestQueues[procedureName] = bluebird.join( \
      @channel.assertQueue queue,
        exclusive: false
        autoDelete: false
        durable: false
      @exchange(),
      (response, exchange) => @channel.bindQueue queue, exchange, procedureName
    ).then -> queue

  responseQueue: () ->
    if @_responseQueue? and not @_responseQueue.isRejected()
      return @_responseQueue

    @_responseQueue = bluebird.resolve \
      @channel.assertQueue null,
        exclusive: true
        autoDelete: true
        durable: false
      .then (response) -> response.queue
