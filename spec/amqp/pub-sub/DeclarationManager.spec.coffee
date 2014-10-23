{Promise} = require 'bluebird'
requireHelper = require '../../require-helper'
DeclarationManager = requireHelper 'amqp/pub-sub/DeclarationManager'

describe 'amqp.pub-sub.DeclarationManager', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['assertExchange']
    @channel.assertExchange.andCallFake (exchange) ->
      Promise.resolve exchange: exchange
    @subject = new DeclarationManager(@channel)

    @error = new Error 'Error message.'

  it 'accepts a channel as a dependency', ->
    expect(@subject.channel).toBe @channel

  describe 'exchange', ->
    it 'delares the exchange correctly', ->
      actual = null
      runs -> @subject.exchange().then (exchange) -> actual = exchange

      waitsFor -> actual isnt null
      runs ->
        expect(actual).toBe 'overpass.pubsub'
        expect(@channel.assertExchange)
          .toHaveBeenCalledWith 'overpass.pubsub', 'topic',
            durable: false
            autoDelete: false

    it 'only declares the exchange once', ->
      actualA = null
      actualB = null
      runs -> Promise.join [
        @subject.exchange().then (exchange) -> actualA = exchange
        @subject.exchange().then (exchange) -> actualB = exchange
      ]

      waitsFor -> actualA isnt null and actualB isnt null
      runs ->
        expect(actualA).toBe 'overpass.pubsub'
        expect(actualB).toBe actualA
        expect(@channel.assertExchange.calls.length).toBe 1

    it 'propagates errors', ->
      actual = null
      @channel.assertExchange.andCallFake () => Promise.reject @error
      runs -> @subject.exchange().catch (error) -> actual = error

      waitsFor -> actual isnt null
      runs -> expect(actual).toBe @error

    it 'can declare the exchange after an initial error', ->
      actualA = null
      actualB = null
      runs ->
        @channel.assertExchange.andCallFake () => Promise.reject @error
        @subject.exchange().catch (error) -> actualA = error
      waitsFor -> actualA isnt null
      runs ->
        @channel.assertExchange.andCallFake (exchange) ->
          Promise.resolve exchange: exchange
        @subject.exchange().then (exchange) -> actualB = exchange

      waitsFor -> actualB isnt null
      runs ->
        expect(actualA).toBe @error
        expect(actualB).toBe 'overpass.pubsub'
