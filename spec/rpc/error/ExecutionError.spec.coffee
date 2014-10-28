requireHelper = require '../../require-helper'
ExecutionError = requireHelper 'rpc/error/ExecutionError'
ResponseCode = requireHelper 'rpc/message/ResponseCode'

describe 'rpc.error.ExecutionError', ->
  beforeEach ->
    @message = 'Error message.'
    @subject = new ExecutionError @message

  it 'stores the error message', ->
    expect(@subject.message).toBe @message

  it 'returns the correct response code', ->
    expect(@subject.responseCode).toBe ResponseCode.ERROR
