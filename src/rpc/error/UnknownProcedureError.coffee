ResponseCode = require "../message/ResponseCode"

module.exports = class UnknownProcedureError extends Error

    constructor: (@procedureName) ->
        @message = "Unknown procedure: #{@procedureName}."
        @responseCode = ResponseCode.UNKNOWN_PROCEDURE
