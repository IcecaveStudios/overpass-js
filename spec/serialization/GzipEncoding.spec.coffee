requireHelper = require '../require-helper'
GzipEncoding = requireHelper 'serialization/GzipEncoding'

describe 'serialization.GzipEncoding', ->

    beforeEach ->
        @subject = new GzipEncoding()

    describe 'encode()', ->

        it 'returns tuple [encodedBuffer, scheme]', (done) ->
            @subject.encode(null, 'hello world').then ([buffer, scheme]) ->
                # expect(buffer).toDeepEqual new Buffer "{ 0 : 31, 1 : 139, 2 : 8, 3 : 0, 4 : 0, 5 : 0, 6 : 0, 7 : 0, 8 : 0, 9 : 3, 10 : 203, 11 : 72, 12 : 205, 13 : 201, 14 : 201, 15 : 87, 16 : 40, 17 : 207, 18 : 47, 19 : 202, 20 : 73, 21 : 1, 22 : 0, 23 : 133, 24 : 17, 25 : 74, 26 : 13, 27 : 11, 28 : 0, 29 : 0, 30 : 0 }"
                done()

        it 'defaults to scheme gzip', (done) ->
            @subject.encode(null, 'hello world').then ([buffer, scheme]) ->
                expect(scheme).toEqual 'gzip'
                done()

    describe 'decode()', ->

        it 'decodes encoded data successfully', (done) ->
            string = 'hello world'
            @subject.encode('gzip', string).then ([b]) =>
                @subject.decode('gzip', b).then (result) ->
                    expect(string).toEqual result.toString()
                    done()

        it 'throws an error when unsupported scheme', (done) ->
            expected = new Error 'Unsupported encoding scheme: foo.'
            @subject.decode('foo', 'bar').catch (err) ->
                expect(err).toEqual expected
                done()
