ResponseCode = require "../message/ResponseCode"

module.exports = class ExecutionError extends Error

    constructor: (@message) -> @responseCode = ResponseCode.ERROR
