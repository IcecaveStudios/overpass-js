requireHelper = require '../../require-helper'
InvalidArgumentsError = requireHelper 'rpc/error/InvalidArgumentsError'
ResponseCode = requireHelper 'rpc/message/ResponseCode'

describe 'rpc.error.InvalidArgumentsError', ->
  beforeEach ->
    @message = 'Error message.'
    @subject = new InvalidArgumentsError @message

  it 'stores the error message', ->
    expect(@subject.message).toBe @message

  it 'returns the correct response code', ->
    expect(@subject.responseCode).toBe ResponseCode.INVALID_ARGUMENTS
