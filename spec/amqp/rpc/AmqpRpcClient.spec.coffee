winston = require 'winston'
requireHelper = require '../../require-helper'
AmqpRpcClient = requireHelper 'amqp/rpc/AmqpRpcClient'
DeclarationManager = requireHelper 'amqp/rpc/DeclarationManager'
MessageSerialization = requireHelper 'rpc/message/serialization/MessageSerialization'

describe 'amqp.rpc.AmqpRpcClient', ->
  beforeEach ->
    @channel = jasmine.createSpyObj 'channel', ['assertExchange', 'assertQueue']
    @timeout = 10
    @declarationManager = jasmine.createSpyObj 'declarationManager', ['exchange']
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
