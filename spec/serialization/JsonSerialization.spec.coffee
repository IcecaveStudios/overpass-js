requireHelper = require '../require-helper'
JsonSerialization = requireHelper 'serialization/JsonSerialization'

describe 'serialization.JsonSerialization', ->
  beforeEach ->
    @subject = new JsonSerialization()

  describe 'serialize', ->
    it 'serializes payloads into JSON', ->
      expect(@subject.serialize({}).toString()).toBe '{}'
      expect(@subject.serialize([]).toString()).toBe '[]'
      expect(@subject.serialize([1, 'false', false]).toString()).toBe '[1,"false",false]'
      expect(@subject.serialize(x: 5).toString()).toBe '{"x":5}'
      expect(@subject.serialize([1, '2']).toString()).toBe '[1,"2"]'

    it 'throws an error when supplied with invalid input', ->
      expected = new Error 'Payload must be an object or an array.'

      expect(=> @subject.serialize(->)).toThrow expected
      expect(=> @subject.serialize(true)).toThrow expected
      expect(=> @subject.serialize(null)).toThrow expected
      expect(=> @subject.serialize(undefined)).toThrow expected
      expect(=> @subject.serialize('foo')).toThrow expected

  describe 'unserialize', ->
    it 'unserializes JSON into payloads', ->
      expect(@subject.unserialize(new Buffer '{}')).toEqual {}
      expect(@subject.unserialize(new Buffer '[]')).toEqual []
      expect(@subject.unserialize(new Buffer '[1,"false",false]')).toEqual [1, 'false', false]
      expect(@subject.unserialize(new Buffer '{"x":5}')).toEqual x: 5
      expect(@subject.unserialize(new Buffer '[1,"2"]')).toEqual [1, '2']

    it 'throws an error when supplied with invalid syntax', ->
      expect(=> @subject.unserialize('{')).toThrow new Error 'Could not unserialize payload.'

    it 'throws an error when supplied with an invalid payload', ->
      expected = new Error 'Payload must be an object or an array.'

      expect(=> @subject.unserialize(new Buffer 'true')).toThrow expected
      expect(=> @subject.unserialize(new Buffer 'null')).toThrow expected
      expect(=> @subject.unserialize(new Buffer '"foo"')).toThrow expected
      expect(=> @subject.unserialize(true)).toThrow expected
      expect(=> @subject.unserialize(1)).toThrow expected

    it 'throws an error when supplied with invalid input', ->
      expected = new Error 'Could not unserialize payload.'

      expect(=> @subject.unserialize(null)).toThrow expected
      expect(=> @subject.unserialize(undefined)).toThrow expected
      expect(=> @subject.unserialize([])).toThrow expected
      expect(=> @subject.unserialize({})).toThrow expected
      expect(=> @subject.unserialize(->)).toThrow expected
