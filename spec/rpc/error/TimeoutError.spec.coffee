requireHelper = require '../../require-helper'
TimeoutError = requireHelper 'rpc/error/TimeoutError'

describe 'rpc.error.TimeoutError', ->
  beforeEach ->
    @timeout = .1
    @subject = new TimeoutError @timeout

  it 'stores the timeout', ->
    expect(@subject.timeout).toBe @timeout

  it 'generates a meaningful error message', ->
    expect(@subject.message).toBe 'RPC call timed out after 0.1 seconds.'
