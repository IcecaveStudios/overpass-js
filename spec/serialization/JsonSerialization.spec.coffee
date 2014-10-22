requireHelper = require '../require-helper'
JsonSerialization = requireHelper 'serialization/JsonSerialization'
SerializeError = requireHelper 'serialization/error/SerializeError'

describe 'serialization.JsonSerialization', ->
  beforeEach ->
    @subject = new JsonSerialization()

  describe 'serialize', ->
    it 'serializes values into JSON', ->
      expect(@subject.serialize({})).toBe '{}'
      expect(@subject.serialize(true)).toBe 'true'
      expect(@subject.serialize('foo')).toBe '"foo"'
      expect(@subject.serialize([1, 'false', false])).toBe '[1,"false",false]'
      expect(@subject.serialize(x: 5)).toBe '{"x":5}'
      expect(@subject.serialize([1, '2'])).toBe '[1,"2"]'
      expect(@subject.serialize(null)).toBe 'null'
      expect(@subject.serialize(undefined)).toBe 'null'

    it 'throws an error when supplied invalid input', ->
      expect(=> @subject.serialize(->)).toThrow new SerializeError()
