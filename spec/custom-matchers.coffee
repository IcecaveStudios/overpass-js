beforeEach ->
  @.addMatchers
    toThrowWithCause: (expected) ->
      throw new Error('Actual is not a function') unless typeof @actual is 'function'

      exception = undefined
      try
        @actual()
      catch exception

      result = exception and @env.equals_(exception, expected)

      if result and expected.cause
        result = exception.cause.message is expected.cause.message and
          exception.cause.constructor.name is expected.cause.constructor.name

      @message = ->
        parts = [
          'Expected function to throw '
          expected.constructor.name + ' '
          jasmine.pp(expected.message) + ' '
        ]

        if expected.cause
          parts.push 'with cause '
          parts.push expected.cause.constructor.name + ' '
          parts.push jasmine.pp(expected.cause.message) + ' '
        else
          parts.push 'without cause '

        parts.push ', but it threw '
        parts.push exception.constructor.name + ' '
        parts.push jasmine.pp(exception.message) + ' '

        if exception.cause
          parts.push 'with cause '
          parts.push exception.cause.constructor.name + ' '
          parts.push jasmine.pp(exception.cause.message)
        else
          parts.push 'without cause'

        parts.join ''

      result
