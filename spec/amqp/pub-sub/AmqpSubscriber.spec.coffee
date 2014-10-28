bluebird = require 'bluebird'
winston = require 'winston'
requireHelper = require '../../require-helper'
AmqpSubscriber = requireHelper 'amqp/pub-sub/AmqpSubscriber'
DeclarationManager = requireHelper 'amqp/pub-sub/DeclarationManager'
JsonSerialization = requireHelper 'serialization/JsonSerialization'

describe 'amqp.pub-sub.AmqpSubscriber', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['bindQueue', 'unbindQueue', 'consume', 'cancel']
    @declarationManager = jasmine.createSpyObj 'declarationManager', ['queue', 'exchange']
    @serialization = new JsonSerialization()
    @logger = jasmine.createSpyObj 'logger', ['debug']
    @subject = new AmqpSubscriber @channel, @declarationManager, @serialization, @logger

    @consumeCallback = null

    @declarationManager.queue.andCallFake -> bluebird.resolve 'queue-name'
    @declarationManager.exchange.andCallFake -> bluebird.resolve 'exchange-name'
    @channel.consume.andCallFake (queue, callback) =>
      @consumeCallback = callback
      bluebird.resolve consumerTag: 'consumer-tag'
    @channel.cancel.andCallFake -> bluebird.resolve()
    @error = new Error 'Error message.'

  it 'stores the supplied dependencies', ->
    expect(@subject.channel).toBe @channel
    expect(@subject.declarationManager).toBe @declarationManager
    expect(@subject.serialization).toBe @serialization
    expect(@subject.logger).toBe @logger

  it 'creates sensible default dependencies', ->
    @subject = new AmqpSubscriber @channel

    expect(@subject.channel).toBe @channel
    expect(@subject.declarationManager).toEqual new DeclarationManager @channel
    expect(@subject.serialization).toEqual new JsonSerialization
    expect(@subject.logger).toBe winston

  describe 'subscribe', ->
    it 'binds correctly', (done) ->
      bluebird.join \
        @subject.subscribe('topic.*.a'),
        @subject.subscribe('topic.?.b'),
        =>
          expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.#.a'
          expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic.*.b'
          expect(@subject._state 'topic.#.a').toBe 'subscribed'
          expect(@subject._state 'topic.*.b').toBe 'subscribed'
          done()

    it 'only binds once for concurrent subscriptions', (done) ->
      bluebird.join \
        @subject.subscribe('topic-name'),
        @subject.subscribe('topic-name'),
        =>
          expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
          expect(@channel.bindQueue.calls.length).toBe 1
          expect(@subject._state 'topic-name').toBe 'subscribed'
          done()

    it 'only binds once for sequential subscriptions', (done) ->
      @subject.subscribe('topic-name')
      .then => @subject.subscribe('topic-name')
      .then =>
        expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.bindQueue.calls.length).toBe 1
        expect(@subject._state 'topic-name').toBe 'subscribed'
        done()

    it 'propagates queue creation errors', (done) ->
      @declarationManager.queue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic-name').catch (actual) =>
        expect(actual).toBe @error
        expect(@channel.bindQueue.calls.length).toBe 0
        expect(@subject._state 'topic-name').toBe 'unsubscribed'
        done()

    it 'propagates exchange creation errors', (done) ->
      @declarationManager.exchange.andCallFake => bluebird.reject @error

      @subject.subscribe('topic-name').catch (actual) =>
        expect(actual).toBe @error
        expect(@channel.bindQueue.calls.length).toBe 0
        expect(@subject._state 'topic-name').toBe 'unsubscribed'
        done()

    it 'propagates binding errors', (done) ->
      @channel.bindQueue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic-name').catch (actual) =>
        expect(actual).toBe @error
        expect(@subject._state 'topic-name').toBe 'unsubscribed'
        done()

    it 'can subscribe after an initial error', (done) ->
      @channel.bindQueue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic-name').catch (actual) =>
        expect(actual).toBe @error
      .then =>
        @channel.bindQueue.andReturn()
        @subject.subscribe('topic-name')
      .then =>
        expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.bindQueue.calls.length).toBe 2
        expect(@subject._state 'topic-name').toBe 'subscribed'
        done()

    it 'can re-subscribe after unsubscribing', (done) ->
      @subject.subscribe('topic-name')
      .then => @subject.unsubscribe('topic-name')
      .then => @subject.subscribe('topic-name')
      .then =>
        expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.bindQueue.calls.length).toBe 2
        expect(@subject._state 'topic-name').toBe 'subscribed'
        done()

    it 're-subscribes after any pending unsubscriptions', (done) ->
      @subject.subscribe 'topic-name'
      @subject.unsubscribe 'topic-name'

      @subject.subscribe('topic-name').then =>
        expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.bindQueue.calls.length).toBe 2
        expect(@subject._state 'topic-name').toBe 'subscribed'
        done()

    it 'starts consuming when subscriptions are added concurrently', (done) ->
      @subject.subscribe 'topic-a'
      @subject.subscribe 'topic-b'

      @subject._consumer.then =>
        expect(@channel.consume).toHaveBeenCalledWith 'queue-name', jasmine.any(Function)
        expect(@channel.consume.calls.length).toBe 1
        expect(@subject._consumerTag).toBe 'consumer-tag'
        expect(@subject._consumerState).toBe 'consuming'
        done()

    it 'starts consuming when subscriptions are added sequentially', (done) ->
      @subject.subscribe('topic-a').then => @subject.subscribe 'topic-b'

      @subject._consumer.then =>
        expect(@channel.consume).toHaveBeenCalledWith 'queue-name', jasmine.any(Function)
        expect(@channel.consume.calls.length).toBe 1
        expect(@subject._consumerTag).toBe 'consumer-tag'
        expect(@subject._consumerState).toBe 'consuming'
        done()

    it 'logs the details', (done) ->
      @logger.debug.andCallFake (message, meta) ->
        expect(message).toBe 'Subscribed to topic "{topic}"'
        expect(meta).toEqual topic: 'topic-name'
        done()

      @subject.subscribe 'topic-name'

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
          expect(@subject._state 'topic.#.a').toBe 'unsubscribed'
          expect(@subject._state 'topic.*.b').toBe 'unsubscribed'
          done()

    it 'only unbinds once for concurrent unsubscriptions', (done) ->
      bluebird.join \
        @subject.unsubscribe('topic-name'),
        @subject.subscribe('topic-name'),
        @subject.unsubscribe('topic-name'),
        @subject.unsubscribe('topic-name'),
        =>
          expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
          expect(@channel.unbindQueue.calls.length).toBe 1
          expect(@subject._state 'topic-name').toBe 'unsubscribed'
          done()

    it 'only unbinds once for sequential unsubscriptions', (done) ->
      @subject.unsubscribe('topic-name')
      .then => @subject.subscribe('topic-name')
      .then => @subject.unsubscribe('topic-name')
      .then => @subject.unsubscribe('topic-name')
      .then =>
        expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.unbindQueue.calls.length).toBe 1
        expect(@subject._state 'topic-name').toBe 'unsubscribed'
        done()

    it 'never unbinds if never bound', (done) ->
      @subject.unsubscribe('topic-name').then =>
        expect(@channel.unbindQueue.calls.length).toBe 0
        expect(@subject._state 'topic-name').toBe 'unsubscribed'
        done()

    it 'propagates unbinding errors', (done) ->
      @channel.unbindQueue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic-name')
      .then => @subject.unsubscribe('topic-name')
      .catch (actual) =>
        expect(actual).toBe @error
        expect(@channel.unbindQueue.calls.length).toBe 1
        expect(@subject._state 'topic-name').toBe 'subscribed'
        done()

    it 'can unsubscribe after an initial error', (done) ->
      @channel.unbindQueue.andCallFake => bluebird.reject @error

      @subject.subscribe('topic-name')
      .then => @subject.unsubscribe('topic-name')
      .catch (actual) =>
        expect(actual).toBe @error
      .then =>
        @channel.unbindQueue.andReturn()
        @subject.unsubscribe('topic-name')
      .then =>
        expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.unbindQueue.calls.length).toBe 2
        expect(@subject._state 'topic-name').toBe 'unsubscribed'
        done()

    it 'can unsubscribe after re-subscribing', (done) ->
      @subject.subscribe('topic-name')
      .then => @subject.unsubscribe('topic-name')
      .then => @subject.subscribe('topic-name')
      .then => @subject.unsubscribe('topic-name')
      .then =>
        expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.unbindQueue.calls.length).toBe 2
        expect(@subject._state 'topic-name').toBe 'unsubscribed'
        done()

    it 'unsubscribes after any pending subscriptions', (done) ->
      @subject.subscribe 'topic-name'

      @subject.unsubscribe('topic-name').then =>
        expect(@channel.bindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@channel.unbindQueue).toHaveBeenCalledWith 'queue-name', 'exchange-name', 'topic-name'
        expect(@subject._state 'topic-name').toBe 'unsubscribed'
        done()

    it 'stops consuming when all subscriptions are removed concurrently', (done) ->
      @subject.subscribe 'topic-a'
      @subject.subscribe 'topic-b'
      @subject.unsubscribe 'topic-a'

      @subject.unsubscribe('topic-b').then =>
        expect(@channel.consume).toHaveBeenCalledWith 'queue-name', jasmine.any(Function)
        expect(@channel.consume.calls.length).toBe 1
        expect(@channel.cancel).toHaveBeenCalledWith 'consumer-tag'
        expect(@channel.cancel.calls.length).toBe 1
        expect(@subject._consumerState).toBe 'detached'
        done()

    it 'stops consuming when all subscriptions are removed sequentially', (done) ->
      @subject.subscribe('topic-a')
      .then => @subject.subscribe('topic-b')
      .then => @subject.unsubscribe('topic-a')
      .then => @subject.unsubscribe('topic-b')
      .then =>
        expect(@channel.consume).toHaveBeenCalledWith 'queue-name', jasmine.any(Function)
        expect(@channel.consume.calls.length).toBe 1
        expect(@channel.cancel).toHaveBeenCalledWith 'consumer-tag'
        expect(@channel.cancel.calls.length).toBe 1
        expect(@subject._consumerState).toBe 'detached'
        done()

    it 'logs the details', (done) ->
      @subject.subscribe('topic-name').then =>
        @logger.debug.andCallFake (message, meta) ->
          expect(message).toBe 'Unsubscribed from topic "{topic}"'
          expect(meta).toEqual topic: 'topic-name'
          done()

      @subject.unsubscribe 'topic-name'

  describe '_consume', ->
    it 'emits generic message events', (done) ->
      @subject.on 'message', (type, payload) ->
        expect(type).toBe 'routing-key'
        expect(payload).toEqual a: 'b', c: 'd'
        done()

      @subject._consume().then =>
        @consumeCallback
          fields: routingKey: 'routing-key'
          content: new Buffer '{"a":"b","c":"d"}'

    it 'emits message events by routing key', (done) ->
      @subject.on 'message.routing-key', (type, payload) ->
        expect(type).toBe 'routing-key'
        expect(payload).toEqual a: 'b', c: 'd'
        done()

      @subject._consume().then =>
        @consumeCallback
          fields: routingKey: 'routing-key'
          content: new Buffer '{"a":"b","c":"d"}'

    it 'can consume after a pending cancel', (done) ->
      @subject._consume()
      @subject._cancelConsume()

      @subject._consume().then =>
        expect(@channel.consume).toHaveBeenCalledWith 'queue-name', jasmine.any(Function)
        expect(@channel.consume.calls.length).toBe 2
        expect(@channel.cancel).toHaveBeenCalledWith 'consumer-tag'
        expect(@channel.cancel.calls.length).toBe 1
        expect(@subject._consumerState).toBe 'consuming'
        done()

    it 'logs the details', (done) ->
      @subject.subscribe('topic-name')
      .then =>
        @logger.debug.andCallFake (message, meta) ->
          expect(message).toBe 'Received {payload} from topic "{topic}"'
          expect(meta).toEqual
            topic: 'routing-key'
            payload: '{"a":"b","c":"d"}'
          done()
      .then =>
        @consumeCallback
          fields: routingKey: 'routing-key'
          content: new Buffer '{"a":"b","c":"d"}'

  describe '_cancelConsume', ->
    it 'correctly handles cancellation when already detatched', (done) ->
      @subject._cancelConsume().then =>
        expect(@channel.consume.calls.length).toBe 0
        expect(@channel.cancel.calls.length).toBe 0
        expect(@subject._consumerState).toBe 'detached'
        done()

    it 'correctly handles a failure', (done) ->
      @channel.cancel.andCallFake => bluebird.reject @error

      @subject._consume()
      .then => @subject._cancelConsume()
      .catch (actual) =>
        expect(actual).toBe @error
        expect(@subject._consumerState).toBe 'consuming'
        done()
