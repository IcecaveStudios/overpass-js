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
    if @_subscriptions[topic]? and not @_subscriptions[topic].isRejected()
      return @_subscriptions[topic]

    # bind the queue to the exchange for this topic
    subscription = bluebird.join \
      @declarationManager.queue(),
      @declarationManager.exchange(),
      (queue, exchange) => @channel.bindQueue queue, exchange, topic

    # on success, clean up any completed un-subscriptions
    subscription = subscription.then =>
      if @_unsubscriptions[topic]? and not @_unsubscriptions[topic].isPending()
        delete @_unsubscriptions[topic]

    # if a pending un-subscription exists, subscribe after it completes
    # this must also work if the un-subscription is rejected
    if @_unsubscriptions[topic]? and @_unsubscriptions[topic].isPending()
      subscription = @_unsubscriptions[topic].then \
        bluebird.resolve(subscription),
        bluebird.resolve(subscription)

    @_subscriptions[topic] = subscription

  unsubscribe: (topic) ->
    topic = @_normalizeTopic topic

    # dont attempt to unbind unless there is a subscription
    return bluebird.resolve() if not @_subscriptions[topic]?

    # return any pre-existing un-subscription for this topic that hasn't failed
    if @_unsubscriptions[topic]? and not @_unsubscriptions[topic].isRejected()
      return @_unsubscriptions[topic]

    # unbind the queue from the exchange for this topic
    unsubscription = bluebird.join \
      @declarationManager.queue(),
      @declarationManager.exchange(),
      (queue, exchange) => @channel.unbindQueue queue, exchange, topic

    # on success, clean up any completed subscriptions
    unsubscription = unsubscription.then =>
      if @_subscriptions[topic]? and not @_subscriptions[topic].isPending()
        delete @_subscriptions[topic]

    # if a pending subscription exists, un-subscribe after it completes
    # this must also work if the subscription is rejected
    if @_subscriptions[topic]? and @_subscriptions[topic].isPending()
      unsubscription = @_subscriptions[topic].then \
        bluebird.resolve(unsubscription),
        bluebird.resolve(unsubscription)

    @_unsubscriptions[topic] = unsubscription

  _normalizeTopic: (topic) ->
    topic.replace(/\*/g, '#').replace /\?/g, '*'
