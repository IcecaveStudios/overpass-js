DeclarationManager = require './DeclarationManager'
JsonSerialization = require '../../serialization/JsonSerialization'

module.exports = class AmqpPublisher
  constructor: (
    @channel,
    @declarationManager = new DeclarationManager(@channel),
    @serialization = new JsonSerialization()
  ) ->

  publish: (topic, payload) ->
    @declarationManager.exchange().then (exchange) =>
      @channel.publish exchange, topic, @serialization.serialize payload
