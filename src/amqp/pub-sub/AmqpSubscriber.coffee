bluebird = require 'bluebird'
{EventEmitter} = require 'events'
DeclarationManager = require './DeclarationManager'
JsonSerialization = require '../../serialization/JsonSerialization'

module.exports = class AmqpSubscriber extends EventEmitter
  constructor: (
    @channel,
    @declarationManager = new DeclarationManager(@channel),
    @serialization = new JsonSerialization()
  ) ->
    @_promises = {}
    @_topicStates = {}
    @_consumer = null
    @_consumerState = 'detached'
    @_consumerTag = null

  subscribe: (topic) ->
    topic = @_normalizeTopic topic

    switch @_state topic
      when 'subscribed'
        bluebird.resolve()
      when 'subscribing'
        @_promises[topic]
      when 'unsubscribed'
        @_setState topic, 'subscribing'
        @_promises[topic] = @_doSubscribe topic
      when 'unsubscribing'
        @_setState topic, 'subscribing'
        @_promises[topic] = @_promises[topic].then => @_doSubscribe topic

  unsubscribe: (topic) ->
    topic = @_normalizeTopic topic

    switch @_state topic
      when 'subscribed'
        @_setState topic, 'unsubscribing'
        @_promises[topic] = @_doUnsubscribe topic
      when 'subscribing'
        @_setState topic, 'unsubscribing'
        @_promises[topic] = @_promises[topic].then => @_doUnsubscribe topic
      when 'unsubscribed'
        bluebird.resolve()
      when 'unsubscribing'
        @_promises[topic]

  _doSubscribe: (topic) ->
    @_consume()
    .then => bluebird.join( \
      @declarationManager.queue(),
      @declarationManager.exchange(),
      (queue, exchange) => @channel.bindQueue queue, exchange, topic
    ).then => @_setState(topic, 'subscribed')
    .catch (error) =>
      @_setState topic, 'unsubscribed'
      throw error

  _doUnsubscribe: (topic) ->
    bluebird.join( \
      @declarationManager.queue(),
      @declarationManager.exchange(),
      (queue, exchange) => @channel.unbindQueue queue, exchange, topic
    ).then => @_setState topic, 'unsubscribed'
    .then =>
      if Object.keys(@_topicStates).length < 1
        @_cancelConsume()
      else return
    .catch (error) =>
      @_setState topic, 'subscribed'
      throw error

  _normalizeTopic: (topic) ->
    topic.replace(/\*/g, '#').replace /\?/g, '*'

  _state: (topic) ->
    @_topicStates[topic] ? 'unsubscribed'

  _setState: (topic, state) ->
    if state is 'unsubscribed'
      delete @_topicStates[topic]
    else
      @_topicStates[topic] = state

  _consume: ->
    switch @_consumerState
      when 'consuming'
        bluebird.resolve()
      when 'attaching'
        @_consumer
      when 'detached'
        @_consumerState = 'attaching'
        @_consumer = @_doConsume()
      when 'cancelling'
        @_consumerState = 'attaching'
        @_consumer = @_consumer.then => @_doConsume()

  _cancelConsume: ->
    switch @_consumerState
      when 'consuming'
        @_consumerState = 'cancelling'
        @_consumer = @_doCancelConsume()
      when 'attaching'
        @_consumerState = 'cancelling'
        @_consumer = @_consumer.then => @_doCancelConsume()
      when 'detached'
        bluebird.resolve()
      when 'cancelling'
        @_consumer

  _doConsume: ->
    consumer = @declarationManager.queue().then (queue) =>
      @channel.consume queue, (message) =>
        type = message.fields.routingKey
        payload = @serialization.unserialize message.content
        @emit 'message', type, payload
        @emit 'message.' + type, type, payload

    consumer
      .then (response) =>
        @_consumerState = 'consuming'
        @_consumerTag = response.consumerTag
      .catch (error) =>
        @_consumerState = 'detached'
        throw error

  _doCancelConsume: ->
    cancel = @channel.cancel @_consumerTag
    cancel
      .then =>
        @_consumerState = 'detached'
        @_consumerTag = null
      .catch (error) =>
        @_consumerState = 'consuming'
        throw error
