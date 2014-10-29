bluebird = require 'bluebird'
winston = require 'winston'
requireHelper = require '../../require-helper'
AmqpPublisher = requireHelper 'amqp/pub-sub/AmqpPublisher'
DeclarationManager = requireHelper 'amqp/pub-sub/DeclarationManager'
JsonSerialization = requireHelper 'serialization/JsonSerialization'

describe 'amqp.pub-sub.AmqpPublisher', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['publish']
    @declarationManager = jasmine.createSpyObj 'declarationManager', ['exchange']
    @serialization = new JsonSerialization()
    @logger = jasmine.createSpyObj 'logger', ['debug']
    @subject = new AmqpPublisher @channel, @declarationManager, @serialization, @logger

  it 'stores the supplied dependencies', ->
    expect(@subject.channel).toBe @channel
    expect(@subject.declarationManager).toBe @declarationManager
    expect(@subject.serialization).toBe @serialization
    expect(@subject.logger).toBe @logger

  it 'creates sensible default dependencies', ->
    @subject = new AmqpPublisher @channel

    expect(@subject.declarationManager).toEqual new DeclarationManager @channel
    expect(@subject.serialization).toEqual new JsonSerialization
    expect(@subject.logger).toBe winston

  describe 'publish()', ->
    beforeEach ->
      @declarationManager.exchange.andCallFake -> bluebird.resolve 'exchange-name'

    it 'publishes messages correctly', (done) ->
      publishedPayload = null
      @channel.publish.andCallFake (exchange, topic, payload) -> publishedPayload = payload
      payload = a: 'b', c: 'd'

      @subject.publish('topic-name', payload).then =>
        expect(@channel.publish).toHaveBeenCalledWith 'exchange-name', 'topic-name', jasmine.any(Buffer)
        expect(publishedPayload.toString()).toBe '{"a":"b","c":"d"}'
        done()

    it 'logs the details', (done) ->
      @logger.debug.andCallFake (message, meta) ->
        expect(message).toBe 'Published {payload} to topic "{topic}"'
        expect(meta).toEqual topic: 'topic-name', payload: '{"a":"b","c":"d"}'
        done()

      @subject.publish 'topic-name', a: 'b', c: 'd'
