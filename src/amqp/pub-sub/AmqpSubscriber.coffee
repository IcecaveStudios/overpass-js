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

    @on 'newListener', (event) =>
      @_onMessageListenerAdded() if event is 'message'
    @on 'removeListener', (event) =>
      @_onMessageListenerRemoved() if event is 'message'

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
    subscription = bluebird.join \
      @declarationManager.queue(),
      @declarationManager.exchange(),
      (queue, exchange) => @channel.bindQueue queue, exchange, topic

    subscription
      .then => @_setState topic, 'subscribed'
      .catch (error) =>
        @_setState topic, 'unsubscribed'
        throw error

  _doUnsubscribe: (topic) ->
    unsubscription = bluebird.join \
      @declarationManager.queue(),
      @declarationManager.exchange(),
      (queue, exchange) => @channel.unbindQueue queue, exchange, topic

    unsubscription
      .then => @_setState topic, 'unsubscribed'
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

  _onMessageListenerAdded: -> @_consume()

  _onMessageListenerRemoved: ->
    @_cancelConsume() if EventEmitter.listenerCount(@, 'message') < 1

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
        @_consumer = @_doCancel()
      when 'attaching'
        @_consumerState = 'cancelling'
        @_consumer = @_consumer.then => @_doCancel()
      when 'detached'
        bluebird.resolve()
      when 'cancelling'
        @_consumer

  _doConsume: ->
    consumer = @declarationManager.queue().then (queue) =>
      @channel.consume queue, (message) =>
        @emit 'message', @serialization.unserialize message.content

    consumer
      .then (response) =>
        @_consumerState = 'consuming'
        @_consumerTag = response.consumerTag
      .catch (error) =>
        @_consumerState = 'detached'
        throw error

  _doCancel: ->
    cancel = @channel.cancel @_consumerTag
    cancel
      .then =>
        console.log 'finished detaching'
        @_consumerState = 'detached'
        @_consumerTag = null
      .catch (error) =>
        @_consumerState = 'consuming'
