requireHelper = require '../require-helper'
JsonSerialization = requireHelper 'serialization/JsonSerialization'

describe 'JsonSerialization', ->
  beforeEach ->
    @subject = new JsonSerialization()

  describe 'serialize', ->
    it 'serializes values into JSON', ->
      expect(@subject.serialize({})).toBe '{}'
      expect(@subject.serialize(true)).toBe 'true'
      expect(@subject.serialize('foo')).toBe '"foo"'
      expect(@subject.serialize([1, 'false', false])).toBe '[1,"false",false]'
      expect(@subject.serialize(x: 5)).toBe '{"x":5}'
