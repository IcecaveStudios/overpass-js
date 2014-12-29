requireHelper = require "../../../require-helper"
JsonSerialization = requireHelper "serialization/JsonSerialization"
MessageSerialization = requireHelper "rpc/message/serialization/MessageSerialization"
Request = requireHelper "rpc/message/Request"
Response = requireHelper "rpc/message/Response"
ResponseCode = requireHelper "rpc/message/ResponseCode"

describe "rpc.message.serialization.MessageSerialization", ->

    beforeEach ->
        @serialization = new JsonSerialization()
        @subject = new MessageSerialization(@serialization)

    it "stores the supplied dependencies", ->
        expect(@subject.serialization).toBe @serialization

    describe "serializeRequest()", ->

        it "serializes requests into JSON", ->
            request = new Request "procedureName", ["a", b: "c", ["d", "e"]]
            actual = @subject.serializeRequest(request).toString()

            expect(actual).toBe '["procedureName",["a",{"b":"c"},["d","e"]]]'

    describe "unserializeResponse()", ->

        it "unserializes responses", ->
            buffer = new Buffer '[0,["a",{"b":"c"},["d","e"]]]'
            actual = @subject.unserializeResponse buffer

            expect(actual.constructor.name).toBe Response.name
            expect(actual.code).toBe ResponseCode.SUCCESS
            expect(actual.extract()).toEqual ["a", b: "c", ["d", "e"]]

        it "throws an error when supplied with invalid syntax", ->
            buffer = new Buffer "{"

            expect(=> @subject.unserializeResponse buffer).toThrow "Response payload is invalid."

        it "throws an error when the payload is not an array", ->
            buffer = new Buffer "{}"

            expect(=> @subject.unserializeResponse buffer).toThrow "Response payload must be a 2-tuple."

        it "throws an error when the payload is not a 2-tuple", ->
            buffer = new Buffer "[0, 1, 2]"

            expect(=> @subject.unserializeResponse buffer).toThrow "Response payload must be a 2-tuple."

        it "throws an error when the response code is unrecognised", ->
            buffer = new Buffer "[1337, {}]"

            expect(=> @subject.unserializeResponse buffer).toThrow "Response code is unrecognised."

        it "throws an error when an error response has a non-string value", ->
            buffer = new Buffer "[10, {}]"

            expect(=> @subject.unserializeResponse buffer).toThrow "Response error message must be a string."

