requireHelper = require '../../require-helper'
Request = requireHelper 'rpc/message/Request'

describe 'rpc.message.Request', ->
  beforeEach ->
    @name = 'procedureName'
    @arguments = ['a', b: 'c', ['d', 'e']]
    @subject = new Request(@name, @arguments)

  it 'stores the suppled name and arguments', ->
    expect(@subject.name).toBe @name
    expect(@subject.arguments).toBe @arguments

  it 'has a meaningful string representation', ->
    expect(@subject.toString()).toBe 'procedureName("a", {"b":"c"}, ["d","e"])'
