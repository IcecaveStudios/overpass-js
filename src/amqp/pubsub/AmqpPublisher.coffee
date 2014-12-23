DeclarationManager = require "./DeclarationManager"
JsonSerialization = require "../../serialization/JsonSerialization"

module.exports = class AmqpPublisher

    constructor: (
        @channel
        @declarationManager = new DeclarationManager(@channel)
        @serialization = new JsonSerialization()
        @logger = require "winston"
    ) ->

    publish: (topic, payload) ->
        payload = @serialization.serialize payload
        @declarationManager.exchange().then (exchange) =>
            @channel.publish exchange, topic, payload
        .tap =>
            @logger.debug 'Published {payload} to topic "{topic}"',
                topic: topic
                payload: payload.toString()
