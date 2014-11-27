bluebird = require 'bluebird'
requireHelper = require '../../require-helper'
DeclarationManager = requireHelper 'amqp/pubsub/DeclarationManager'

describe 'amqp.pubsub.DeclarationManager', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['assertExchange', 'assertQueue']
    @subject = new DeclarationManager @channel

    @error = new Error 'Error message.'

  it 'stores the supplied dependencies', ->
    expect(@subject.channel).toBe @channel

  describe 'exchange()', ->
    beforeEach ->
      @channel.assertExchange.andCallFake (exchange) -> bluebird.resolve exchange: exchange

    it 'delares the exchange correctly', (done) ->
      @subject.exchange().then (actual) =>
        expect(actual).toBe 'overpass/pubsub'
        expect(@channel.assertExchange)
          .toHaveBeenCalledWith 'overpass/pubsub', 'topic', autoDelete: false, durable: false
        done()

    it 'only declares the exchange once', (done) ->
      bluebird.join \
        @subject.exchange(),
        @subject.exchange(),
        (actualA, actualB) =>
          expect(actualA).toBe 'overpass/pubsub'
          expect(actualB).toBe actualA
          expect(@channel.assertExchange.calls.length).toBe 1
          done()

    it 'propagates errors', (done) ->
      @channel.assertExchange.andCallFake => bluebird.reject @error

      @subject.exchange().catch (actual) =>
        expect(actual).toBe @error
        done()

    it 'can declare the exchange after an initial error', (done) ->
      @channel.assertExchange.andCallFake => bluebird.reject @error

      @subject.exchange().catch (actual) =>
        expect(actual).toBe @error
      .then =>
        @channel.assertExchange.andCallFake (exchange) -> bluebird.resolve exchange: exchange
        @subject.exchange()
      .then (actual) ->
        expect(actual).toBe 'overpass/pubsub'
        done()

  describe 'queue()', ->
    beforeEach ->
      @channel.assertQueue.andCallFake -> bluebird.resolve queue: 'queue-name'

    it 'delares the queue correctly', (done) ->
      @subject.queue().then (actual) =>
        expect(actual).toBe 'queue-name'
        expect(@channel.assertQueue).toHaveBeenCalledWith null,
            exclusive: true
            autoDelete: true
            durable: false
        done()

    it 'only declares the queue once', (done) ->
      bluebird.join \
        @subject.queue(),
        @subject.queue(),
        (actualA, actualB) =>
          expect(actualA).toBe 'queue-name'
          expect(actualB).toBe actualA
          expect(@channel.assertQueue.calls.length).toBe 1
          done()

    it 'propagates errors', (done) ->
      @channel.assertQueue.andCallFake => bluebird.reject @error

      @subject.queue().catch (actual) =>
        expect(actual).toBe @error
        done()

    it 'can declare the queue after an initial error', (done) ->
      @channel.assertQueue.andCallFake => bluebird.reject @error

      @subject.queue().catch (actual) =>
        expect(actual).toBe @error
      .then =>
        @channel.assertQueue.andCallFake (queue) -> bluebird.resolve queue: 'queue-name'
        @subject.queue()
      .then (actual) ->
        expect(actual).toBe 'queue-name'
        done()
