bluebird = require "bluebird"
zlib = require 'zlib'

{Promise} = bluebird

#
# Defines a serialization encoding scheme.
#
module.exports = class GzipEncoding

    constructor: ->
        @_isEnabled = true

    #
    # Encode the given buffer.
    #
    # @param string|null $encoding The encoding to use, or null to choose automatically.
    # @param string buffer The buffer to encode.
    #
    # @return tuple<string, string|null> The encoded buffer, and the actual encoding use (null = none).
    #
    encode: (scheme, buffer) =>
        return new Promise (resolve, reject) =>

            if scheme is null
                scheme = 'gzip'

            if @_isEnabled and scheme is 'gzip'
                return zlib.gzip buffer, (err, result) ->
                    resolve [
                        result
                        'gzip'
                    ]

            return resolve [buffer, null]

    #
    # Decode the given buffer.
    #
    # @param string $encoding The encoding to use.a
    # @param string buffer The buffer to decode.
    #
    # @return string
    #
    decode: (scheme, buffer) =>
        return new Promise (resolve, reject) =>

            if @_isEnabled and scheme is 'gzip'
                return zlib.gunzip buffer, (err, result) ->
                    resolve result

            throw new Error('Unsupported encoding scheme: ' + scheme + '.')
