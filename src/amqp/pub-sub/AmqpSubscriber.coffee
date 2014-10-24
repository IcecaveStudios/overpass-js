bluebird = require 'bluebird'
DeclarationManager = require './DeclarationManager'
JsonSerialization = require '../../serialization/JsonSerialization'

module.exports = class AmqpSubscriber
  constructor: (
    @channel,
    @declarationManager = new DeclarationManager(@channel),
    @serialization = new JsonSerialization()
  ) ->
    @_subscriptions = {}
    @_unsubscriptions = {}

  subscribe: (topic) ->
    topic = @_normalizeTopic topic

    # return any pre-existing subscription for this topic that hasn't failed
    return @_subscriptions[topic] if @_subscriptions[topic]? and not
      @_subscriptions[topic].isRejected()

    # bind a new queue to the exchange for this topic
    subscription = bluebird.join \
      @declarationManager.queue(),
      @declarationManager.exchange(),
      (queue, exchange) => @channel.bindQueue queue, exchange, topic

    # on success, clean up any completed unsubscriptions
    subscription = subscription.then =>
      if @_unsubscriptions[topic]? and not @_unsubscriptions[topic].isPending()
        delete @_unsubscriptions[topic]

    # if a pending unsubscription exists, subscribe after it completes
    # this must also work if the unsubscription is rejected
    if @_unsubscriptions[topic]? and @_unsubscriptions[topic].isPending()
      subscription = @_unsubscriptions[topic].then \
        bluebird.resolve(subscription),
        bluebird.resolve(subscription)

    @_subscriptions[topic] = subscription

  _normalizeTopic: (topic) ->
    topic.replace(/\*/g, '#').replace /\?/g, '*'
