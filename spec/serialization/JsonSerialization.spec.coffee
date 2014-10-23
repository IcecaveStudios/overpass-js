requireHelper = require '../require-helper'
JsonSerialization = requireHelper 'serialization/JsonSerialization'

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
      expected = new Error 'Payload must be an object or an array.'

      expect(=> @subject.serialize(->)).toThrow expected
      expect(=> @subject.serialize(true)).toThrow expected
      expect(=> @subject.serialize(null)).toThrow expected
      expect(=> @subject.serialize(undefined)).toThrow expected
      expect(=> @subject.serialize('foo')).toThrow expected

  describe 'unserialize', ->
    it 'unserializes JSON into payloads', ->
      expect(@subject.unserialize('{}')).toEqual {}
      expect(@subject.unserialize('[]')).toEqual []
      expect(@subject.unserialize('[1,"false",false]')).toEqual [1, 'false', false]
      expect(@subject.unserialize('{"x":5}')).toEqual x: 5
      expect(@subject.unserialize('[1,"2"]')).toEqual [1, '2']

    it 'throws an error when supplied with invalid syntax', ->
      expect(=> @subject.unserialize('{')).toThrow new SyntaxError 'Unexpected end of input'

    it 'throws an error when supplied with an invalid payload', ->
      expected = new Error 'Payload must be an object or an array.'

      expect(=> @subject.unserialize('true')).toThrow expected
      expect(=> @subject.unserialize('null')).toThrow expected
      expect(=> @subject.unserialize('"foo"')).toThrow expected

    it 'throws an error when supplied with invalid input', ->
      expected = new Error 'Could not unserialize payload.'

      expect(=> @subject.unserialize(null)).toThrow expected
      expect(=> @subject.unserialize(undefined)).toThrow expected
      expect(=> @subject.unserialize(true)).toThrow expected
      expect(=> @subject.unserialize(1)).toThrow expected
      expect(=> @subject.unserialize([])).toThrow expected
      expect(=> @subject.unserialize({})).toThrow expected
      expect(=> @subject.unserialize(->)).toThrow expected
