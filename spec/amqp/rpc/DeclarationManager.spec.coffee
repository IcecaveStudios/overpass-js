bluebird = require 'bluebird'
requireHelper = require '../../require-helper'
DeclarationManager = requireHelper 'amqp/rpc/DeclarationManager'

describe 'amqp.rpc.DeclarationManager', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['assertExchange', 'assertQueue']
    @subject = new DeclarationManager @channel

    @channel.assertQueue.andCallFake (queue) -> bluebird.resolve queue: queue

    @error = new Error 'Error message.'

  it 'stores the supplied dependencies', ->
    expect(@subject.channel).toBe @channel

  describe 'exchange', ->
    beforeEach ->
      @channel.assertExchange.andCallFake (exchange) -> bluebird.resolve exchange: exchange

    it 'delares the exchange correctly', (done) ->
      @subject.exchange().then (actual) =>
        expect(actual).toBe 'overpass/rpc'
        expect(@channel.assertExchange)
          .toHaveBeenCalledWith 'overpass/rpc', 'direct', autoDelete: false, durable: false
        done()

    it 'only declares the exchange once', (done) ->
      bluebird.join \
        @subject.exchange(),
        @subject.exchange(),
        (actualA, actualB) =>
          expect(actualA).toBe 'overpass/rpc'
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
        expect(actual).toBe 'overpass/rpc'
        done()

  describe 'requestQueue', ->
    it 'delares queues correctly', (done) ->
      @subject.requestQueue('procedureA').then (actual) =>
        expect(actual).toBe 'overpass/rpc/procedureA'
        expect(@channel.assertQueue).toHaveBeenCalledWith 'overpass/rpc/procedureA',
          exclusive: false
          autoDelete: false
          durable: false
        done()

    it 'only declares one queue per procedure', (done) ->
      bluebird.join \
        @subject.requestQueue('procedureA'),
        @subject.requestQueue('procedureB'),
        @subject.requestQueue('procedureA'),
        @subject.requestQueue('procedureB'),
        (actualA, actualB, actualC, actualD) =>
          expect(actualA).toBe 'overpass/rpc/procedureA'
          expect(actualB).toBe 'overpass/rpc/procedureB'
          expect(actualC).toBe actualA
          expect(actualD).toBe actualB
          expect(@channel.assertQueue.calls.length).toBe 2
          done()

    it 'propagates errors', (done) ->
      @channel.assertQueue.andCallFake => bluebird.reject @error

      @subject.requestQueue('procedureA').catch (actual) =>
        expect(actual).toBe @error
        done()

    it 'can declare the queue after an initial error', (done) ->
      @channel.assertQueue.andCallFake => bluebird.reject @error

      @subject.requestQueue('procedureA').catch (actual) =>
        expect(actual).toBe @error
      .then =>
        @channel.assertQueue.andCallFake (queue) -> bluebird.resolve queue: queue
        @subject.requestQueue('procedureA')
      .then (actual) ->
        expect(actual).toBe 'overpass/rpc/procedureA'
        done()

  describe 'responseQueue', ->
    beforeEach ->
      @channel.assertQueue.andCallFake -> bluebird.resolve queue: 'queue-name'

    it 'delares the queue correctly', (done) ->
      @subject.responseQueue().then (actual) =>
        expect(actual).toBe 'queue-name'
        expect(@channel.assertQueue).toHaveBeenCalledWith null, exclusive: true, autoDelete: true, durable: false
        done()

    it 'only declares the queue once', (done) ->
      bluebird.join \
        @subject.responseQueue(),
        @subject.responseQueue(),
        (actualA, actualB) =>
          expect(actualA).toBe 'queue-name'
          expect(actualB).toBe actualA
          expect(@channel.assertQueue.calls.length).toBe 1
          done()

    it 'propagates errors', (done) ->
      @channel.assertQueue.andCallFake => bluebird.reject @error

      @subject.responseQueue().catch (actual) =>
        expect(actual).toBe @error
        done()

    it 'can declare the queue after an initial error', (done) ->
      @channel.assertQueue.andCallFake => bluebird.reject @error

      @subject.responseQueue().catch (actual) =>
        expect(actual).toBe @error
      .then =>
        @channel.assertQueue.andCallFake (queue) -> bluebird.resolve queue: 'queue-name'
        @subject.responseQueue()
      .then (actual) ->
        expect(actual).toBe 'queue-name'
        done()
