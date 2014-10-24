bluebird = require 'bluebird'
requireHelper = require '../../require-helper'
AmqpSubscriber = requireHelper 'amqp/pub-sub/AmqpSubscriber'
DeclarationManager = requireHelper 'amqp/pub-sub/DeclarationManager'
JsonSerialization = requireHelper 'serialization/JsonSerialization'

describe 'amqp.pub-sub.AmqpSubscriber', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['bindQueue', 'unbindQueue']
    @declarationManager = jasmine.createSpyObj 'declarationManager', ['queue', 'exchange']
    @serialization = new JsonSerialization()
    @subject = new AmqpSubscriber @channel, @declarationManager, @serialization

    @declarationManager.queue.andCallFake -> bluebird.resolve 'queue-name'
    @declarationManager.exchange.andCallFake -> bluebird.resolve 'exchange-name'
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
    it 'binds correctly', (done) ->
      bluebird.join \
        @subject.subscribe('topic.*.a'),
        @subject.subscribe('topic.?.b'),
        =>
          expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.#.a'
          expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.*.b'
          done()

    it 'only binds if not already bound', (done) ->
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

  describe 'unsubscribe', ->
    it 'unbinds correctly', (done) ->
      bluebird.join \
        @subject.subscribe('topic.*.a'),
        @subject.unsubscribe('topic.*.a'),
        @subject.subscribe('topic.?.b'),
        @subject.unsubscribe('topic.?.b'),
        =>
          expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.#.a'
          expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.*.b'
          done()

    it 'only unbinds if already bound', (done) ->
      bluebird.join \
        @subject.unsubscribe('topic.*.a'),
        @subject.subscribe('topic.*.a'),
        @subject.unsubscribe('topic.*.a'),
        @subject.unsubscribe('topic.*.a'),
        =>
          expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.#.a'
          expect(@channel.unbindQueue.calls.length).toBe 1
          done()

    it 'never unbinds if never bound', (done) ->
      @subject.unsubscribe('topic.*.a').then =>
          expect(@channel.unbindQueue.calls.length).toBe 0
          done()

    it 'propagates unbinding errors', (done) ->
      @channel.unbindQueue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic.*.a')
        .then => @subject.unsubscribe('topic.*.a')
        .catch (actual) =>
          expect(actual).toBe @error
          expect(@channel.unbindQueue.calls.length).toBe 1
          done()

    it 'can unsubscribe after an initial error', (done) ->
      @channel.unbindQueue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic.*.a')
      .then => @subject.unsubscribe('topic.*.a')
      .catch (actual) =>
        expect(actual).toBe @error
      .then =>
        @channel.unbindQueue.andReturn()
        @subject.unsubscribe('topic.*.a')
      .then =>
        expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.#.a'
        expect(@channel.unbindQueue.calls.length).toBe 2
        done()
