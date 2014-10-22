requireHelper = require '../../require-helper'
UnserializeError = requireHelper 'serialization/error/UnserializeError'

describe 'serialization.error.UnserializeError', ->
  beforeEach ->
    @cause = new Error
    @subject = new UnserializeError(@cause)

  it 'has a descriptive message', ->
    expect(@subject.message).toBe 'Could not unserialize payload.'

  it 'supports error chaining', ->
    expect(@subject.cause).toBe @cause
