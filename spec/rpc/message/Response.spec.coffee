requireHelper = require '../../require-helper'
ExecutionError = requireHelper 'rpc/error/ExecutionError'
InvalidMessageError = requireHelper 'rpc/error/InvalidMessageError'
Response = requireHelper 'rpc/message/Response'
ResponseCode = requireHelper 'rpc/message/ResponseCode'
UnknownProcedureError = requireHelper 'rpc/error/UnknownProcedureError'

describe 'rpc.message.Response', ->
  describe 'with a successful response code', ->
    beforeEach ->
      @code = ResponseCode.SUCCESS
      @value = ['a', b: 'c', ['d', 'e']]
      @subject = new Response @code, @value

    it 'stores the suppled response code and value', ->
      expect(@subject.code).toBe @code
      expect(@subject.value).toBe @value

    it 'extracts to a returned value', ->
      expect(@subject.extract()).toBe @value

    it 'has a meaningful string representation', ->
      expect(@subject.toString()).toBe 'SUCCESS(["a",{"b":"c"},["d","e"]])'

  describe 'with an error response code', ->
    beforeEach ->
      @code = ResponseCode.ERROR
      @value = 'Error message.'
      @subject = new Response @code, @value

    it 'stores the suppled response code and value', ->
      expect(@subject.code).toBe @code
      expect(@subject.value).toBe @value

    it 'extracts to a thrown execution error', (done) ->
      expected = new ExecutionError @value

      try
        @subject.extract()
      catch error
        expect(error.constructor.name).toBe expected.constructor.name
        expect(error.message).toBe expected.message
        done()

    it 'has a meaningful string representation', ->
      expect(@subject.toString()).toBe 'ERROR(Error message.)'

  describe 'with an invalid message response code', ->
    beforeEach ->
      @code = ResponseCode.INVALID_MESSAGE
      @value = 'Error message.'
      @subject = new Response @code, @value

    it 'extracts to a thrown invalid message error', (done) ->
      expected = new InvalidMessageError @value

      try
        @subject.extract()
      catch error
        expect(error.constructor.name).toBe expected.constructor.name
        expect(error.message).toBe expected.message
        done()

  describe 'with an unknown procedure response code', ->
    beforeEach ->
      @code = ResponseCode.UNKNOWN_PROCEDURE
      @value = 'procedureName'
      @subject = new Response @code, @value

    it 'extracts to a thrown unknown procedure error', (done) ->
      expected = new UnknownProcedureError @value

      try
        @subject.extract()
      catch error
        expect(error.constructor.name).toBe expected.constructor.name
        expect(error.message).toBe expected.message
        done()
