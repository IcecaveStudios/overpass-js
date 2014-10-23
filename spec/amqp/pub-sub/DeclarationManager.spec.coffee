{Promise} = require 'bluebird'
requireHelper = require '../../require-helper'
DeclarationManager = requireHelper 'amqp/pub-sub/DeclarationManager'

describe 'amqp.pub-sub.DeclarationManager', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['assertExchange']
    @channel.assertExchange.andCallFake (exchange) -> new Promise (resolve) -> resolve exchange: exchange
    @subject = new DeclarationManager(@channel)

  it 'accepts a channel as a dependency', ->
    expect(@subject.channel).toBe @channel

  describe 'exchange', ->
    it 'delares the exchange correctly', ->
      done = false
      actual = null

      runs -> @subject.exchange().then (exchange) ->
        actual = exchange
        done = true

      waitsFor -> done

      runs ->
        expect(actual).toBe 'overpass.pubsub'
        expect(@channel.assertExchange).toHaveBeenCalledWith 'overpass.pubsub', 'topic',
          durable: false
          autoDelete: false
