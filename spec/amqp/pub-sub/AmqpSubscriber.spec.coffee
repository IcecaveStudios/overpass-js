bluebird = require 'bluebird'
requireHelper = require '../../require-helper'
AmqpSubscriber = requireHelper 'amqp/pub-sub/AmqpSubscriber'
DeclarationManager = requireHelper 'amqp/pub-sub/DeclarationManager'
JsonSerialization = requireHelper 'serialization/JsonSerialization'

describe 'amqp.pub-sub.AmqpSubscriber', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['bindQueue']
    @declarationManager = jasmine.createSpyObj 'declarationManager', ['queue', 'exchange']
    @serialization = new JsonSerialization()
    @subject = new AmqpSubscriber @channel, @declarationManager, @serialization

    @error = new Error 'Error message.'

  it 'stores the supplied dependencies', ->
    expect(@subject.channel).toBe @channel
    expect(@subject.declarationManager).toBe @declarationManager
    expect(@subject.serialization).toBe @serialization

  it 'creates sensible default dependencies', ->
    @subject = new AmqpSubscriber @channel

    expect(@subject.channel).toBe @channel
    expect(@subject.declarationManager).toEqual new DeclarationManager @channel
    expect(@subject.serialization).toEqual new JsonSerialization

  describe 'subscribe', ->
    beforeEach ->
      @declarationManager.queue.andCallFake -> bluebird.resolve 'queue-name'
      @declarationManager.exchange.andCallFake -> bluebird.resolve 'exchange-name'

    it 'binds to topic queues', (done) ->
      bluebird.join \
        @subject.subscribe('topic.*.a'),
        @subject.subscribe('topic.?.b'),
        =>
          expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.#.a'
          expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.*.b'
          done()

    it 'only binds once for each topic', (done) ->
      bluebird.join \
        @subject.subscribe('topic.*.a'),
        @subject.subscribe('topic.*.a'),
        =>
          expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.#.a'
          expect(@channel.bindQueue.calls.length).toBe 1
          done()

    it 'propagates queue creation errors', (done) ->
      @declarationManager.queue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic.*.a').catch (actual) =>
        expect(actual).toBe @error
        expect(@channel.bindQueue.calls.length).toBe 0
        done()

    it 'propagates exchange creation errors', (done) ->
      @declarationManager.exchange.andCallFake => bluebird.reject @error

      @subject.subscribe('topic.*.a').catch (actual) =>
        expect(actual).toBe @error
        expect(@channel.bindQueue.calls.length).toBe 0
        done()

    it 'propagates binding errors', (done) ->
      @channel.bindQueue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic.*.a').catch (actual) =>
        expect(actual).toBe @error
        done()

    it 'can subscribe after an initial error', (done) ->
      @channel.bindQueue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic.*.a').catch (actual) =>
        expect(actual).toBe @error
      .then =>
        @channel.bindQueue.andReturn()
        @subject.subscribe('topic.*.a')
      .then =>
        expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.#.a'
        expect(@channel.bindQueue.calls.length).toBe 2
        done()
