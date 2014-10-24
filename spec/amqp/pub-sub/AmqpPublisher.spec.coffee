{Promise} = require 'bluebird'
requireHelper = require '../../require-helper'
AmqpPublisher = requireHelper 'amqp/pub-sub/AmqpPublisher'
DeclarationManager = requireHelper 'amqp/pub-sub/DeclarationManager'
JsonSerialization = requireHelper 'serialization/JsonSerialization'

describe 'amqp.pub-sub.AmqpPublisher', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['publish']
    @declarationManager = jasmine.createSpyObj 'declarationManager', ['exchange']
    @serialization = new JsonSerialization()
    @subject = new AmqpPublisher @channel, @declarationManager, @serialization

  it 'stores the supplied dependencies', ->
    expect(@subject.channel).toBe @channel
    expect(@subject.declarationManager).toBe @declarationManager
    expect(@subject.serialization).toBe @serialization

  it 'creates sensible default dependencies', ->
    @subject = new AmqpPublisher @channel

    expect(@subject.channel).toBe @channel
    expect(@subject.declarationManager).toEqual new DeclarationManager @channel
    expect(@subject.serialization).toEqual new JsonSerialization

  describe 'publish', ->
    it 'publishes messages correctly', ->
      publishedPayload = null
      @channel.publish.andCallFake (exchange, topic, payload) ->
        publishedPayload = payload
        Promise.resolve true
      @declarationManager.exchange.andCallFake -> Promise.resolve 'exchange-name'
      actual = null
      payload =
        a: 'b'
        c: 'd'
      runs -> @subject.publish('topic-name', payload).then (result) -> actual = result

      waitsFor -> actual isnt null
      runs ->
        expect(actual).toBe true
        expect(@channel.publish).toHaveBeenCalledWith 'exchange-name', 'topic-name', jasmine.any(Buffer)
        expect(publishedPayload.toString()).toBe '{"a":"b","c":"d"}'
