bluebird = require 'bluebird'
winston = require 'winston'
requireHelper = require '../../require-helper'
AmqpRpcClient = requireHelper 'amqp/rpc/AmqpRpcClient'
DeclarationManager = requireHelper 'amqp/rpc/DeclarationManager'
MessageSerialization = requireHelper 'rpc/message/serialization/MessageSerialization'

describe 'amqp.rpc.AmqpRpcClient', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['consume', 'publish']
    @timeout = 10
    @declarationManager = jasmine.createSpyObj 'declarationManager', ['exchange', 'requestQueue', 'responseQueue']
    @serialization = new MessageSerialization()
    @logger = jasmine.createSpyObj 'logger', ['debug']
    @subject = new AmqpRpcClient @channel, @timeout, @declarationManager, @serialization, @logger

  it 'stores the supplied dependencies', ->
    expect(@subject.channel).toBe @channel
    expect(@subject.timeout).toBe @timeout
    expect(@subject.declarationManager).toBe @declarationManager
    expect(@subject.serialization).toBe @serialization
    expect(@subject.logger).toBe @logger

  it 'creates sensible default dependencies', ->
    @subject = new AmqpRpcClient @channel

    expect(@subject.timeout).toBe 10
    expect(@subject.declarationManager).toEqual new DeclarationManager @channel
    expect(@subject.serialization).toEqual new MessageSerialization
    expect(@subject.logger).toBe winston

  describe 'invocation methods', ->
    beforeEach ->
      @consumeCallback = null
      @publishedPayload = null
      @publishedId = null

      @declarationManager.exchange.andCallFake -> bluebird.resolve 'exchange-name'
      @declarationManager.responseQueue.andCallFake () -> bluebird.resolve 'queue-name'
      @channel.consume.andCallFake (queue, callback) =>
        @consumeCallback = callback
        bluebird.resolve()
      @channel.publish.andCallFake (exchange, topic, payload, options) =>
        @publishedPayload = payload
        @publishedId = options.correlationId
        @consumeCallback
          properties:
            correlationId: options.correlationId
          content: new Buffer '[0,["a",{"b":"c"},["d","e"]]]'
        bluebird.resolve()

    describe 'invokeArray()', ->
      it 'makes calls correctly', (done) ->
        @subject.invokeArray('procedureA', ['a', 'b', c: 'd'])
        .then =>
          expect(@declarationManager.requestQueue).toHaveBeenCalledWith 'procedureA'
          expect(@channel.publish).toHaveBeenCalledWith 'exchange-name', 'procedureA', jasmine.any(Buffer),
            replyTo: 'queue-name'
            correlationId: @publishedId
            expiration: @timeout * 1000
          done()

