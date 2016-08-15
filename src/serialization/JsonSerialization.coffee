module.exports = class JsonSerialization

    serialize: (payload) ->
        if typeof payload not in ["object", "array"] or payload is null
            throw new Error "Payload must be an object or an array."

        new Buffer JSON.stringify payload

    unserialize: (buffer) ->
        try
            payload = JSON.parse buffer.toString()
        catch
            throw new Error "Could not unserialize payload."

        if typeof payload not in ["object", "array"] or payload is null
            throw new Error "Payload must be an object or an array."

        payload
