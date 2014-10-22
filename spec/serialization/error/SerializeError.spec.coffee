requireHelper = require '../../require-helper'
SerializeError = requireHelper 'serialization/error/SerializeError'

describe 'serialization.error.SerializeError', ->
  beforeEach ->
    @cause = new Error()
    @subject = new SerializeError(@cause)

  it 'has a descriptive message', ->
    expect(@subject.message).toBe 'Could not serialize payload.'

  it 'supports error chaining', ->
    expect(@subject.cause).toBe @cause
