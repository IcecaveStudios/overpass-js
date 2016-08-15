ResponseCode = require "../message/ResponseCode"

module.exports = class InvalidMessageError extends Error

    constructor: (@message) -> @responseCode = ResponseCode.INVALID_MESSAGE
