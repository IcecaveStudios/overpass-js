requireHelper = require '../require-helper'
SerializeError = requireHelper 'serialization/error/SerializeError'

describe 'SerializeError', ->
  beforeEach ->
    @subject = new SerializeError()

  it 'has a descriptive message', ->
    expect(@subject.message).toBe 'Could not serialize payload.'
