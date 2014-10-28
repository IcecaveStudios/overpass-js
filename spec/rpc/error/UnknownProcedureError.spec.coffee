requireHelper = require '../../require-helper'
UnknownProcedureError = requireHelper 'rpc/error/UnknownProcedureError'
ResponseCode = requireHelper 'rpc/message/ResponseCode'

describe 'rpc.error.UnknownProcedureError', ->
  beforeEach ->
    @procedureName = 'procedureName'
    @subject = new UnknownProcedureError @procedureName

  it 'stores the procedure name', ->
    expect(@subject.procedureName).toBe @procedureName

  it 'generates a meaningful error message', ->
    expect(@subject.message).toBe 'Unknown procedure: procedureName.'

  it 'returns the correct response code', ->
    expect(@subject.responseCode).toBe ResponseCode.UNKNOWN_PROCEDURE
