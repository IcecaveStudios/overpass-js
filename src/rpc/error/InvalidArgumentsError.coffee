ResponseCode = require "../message/ResponseCode"

module.exports = class InvalidArgumentsError extends Error

    constructor: (@message) -> @responseCode = ResponseCode.INVALID_ARGUMENTS
