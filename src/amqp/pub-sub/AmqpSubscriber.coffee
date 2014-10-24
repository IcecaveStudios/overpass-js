bluebird = require 'bluebird'
DeclarationManager = require './DeclarationManager'
JsonSerialization = require '../../serialization/JsonSerialization'

module.exports = class AmqpSubscriber
  constructor: (
    @channel,
    @declarationManager = new DeclarationManager(@channel),
    @serialization = new JsonSerialization()
  ) ->
    @_promises = {}
    @_topicStates = {}

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
