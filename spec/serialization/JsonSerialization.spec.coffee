require '../custom-matchers'
requireHelper = require '../require-helper'
JsonSerialization = requireHelper 'serialization/JsonSerialization'
SerializeError = requireHelper 'serialization/error/SerializeError'
UnserializeError = requireHelper 'serialization/error/UnserializeError'

describe 'serialization.JsonSerialization', ->
  beforeEach ->
    @subject = new JsonSerialization()

  describe 'serialize', ->
    it 'serializes payloads into JSON', ->
      expect(@subject.serialize({})).toBe '{}'
      expect(@subject.serialize([])).toBe '[]'
      expect(@subject.serialize([1, 'false', false])).toBe '[1,"false",false]'
      expect(@subject.serialize(x: 5)).toBe '{"x":5}'
      expect(@subject.serialize([1, '2'])).toBe '[1,"2"]'

    it 'throws an error when supplied with invalid input', ->
      expect(=> @subject.serialize(->)).toThrow new SerializeError()
      expect(=> @subject.serialize(true)).toThrow new SerializeError()
      expect(=> @subject.serialize(null)).toThrow new SerializeError()
      expect(=> @subject.serialize(undefined)).toThrow new SerializeError()
      expect(=> @subject.serialize('foo')).toThrow new SerializeError()

  describe 'unserialize', ->
    it 'unserializes JSON into payloads', ->
      expect(@subject.unserialize('{}')).toEqual {}
      expect(@subject.unserialize('[]')).toEqual []
      expect(@subject.unserialize('[1,"false",false]')).toEqual [1, 'false', false]
      expect(@subject.unserialize('{"x":5}')).toEqual x: 5
      expect(@subject.unserialize('[1,"2"]')).toEqual [1, '2']

    it 'throws an error when supplied with invalid syntax', ->
      expected = new UnserializeError(new SyntaxError('Unexpected end of input'))
      expect(=> @subject.unserialize('{')).toThrowWithCause expected

    it 'throws an error when supplied with an invalid payload', ->
      expect(=> @subject.unserialize('true')).toThrow new UnserializeError()
      expect(=> @subject.unserialize('null')).toThrow new UnserializeError()
      expect(=> @subject.unserialize('"foo"')).toThrow new UnserializeError()

    it 'throws an error when supplied with invalid input', ->
      expect(=> @subject.unserialize(null)).toThrow new UnserializeError()
      expect(=> @subject.unserialize(undefined)).toThrow new UnserializeError()
      expect(=> @subject.unserialize(true)).toThrow new UnserializeError()
      expect(=> @subject.unserialize(1)).toThrow new UnserializeError()
      expect(=> @subject.unserialize([])).toThrow new UnserializeError()
      expect(=> @subject.unserialize({})).toThrow new UnserializeError()
      expect(=> @subject.unserialize(->)).toThrow new UnserializeError()
