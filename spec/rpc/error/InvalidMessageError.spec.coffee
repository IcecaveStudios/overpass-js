requireHelper = require '../../require-helper'
InvalidMessageError = requireHelper 'rpc/error/InvalidMessageError'
ResponseCode = requireHelper 'rpc/message/ResponseCode'

describe 'rpc.error.InvalidMessageError', ->
  beforeEach ->
    @message = 'Error message.'
    @subject = new InvalidMessageError @message

  it 'stores the error message', ->
    expect(@subject.message).toBe @message

  it 'returns the correct response code', ->
    expect(@subject.responseCode).toBe ResponseCode.INVALID_MESSAGE
