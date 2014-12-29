bluebird = require "bluebird"
winston = require "winston"
requireHelper = require "../require-helper"
Subscriber = requireHelper "pubsub/Subscriber"
Subscription = requireHelper "pubsub/Subscription"

describe "pubsub.Subscriber", ->

    beforeEach ->
        @driver = jasmine.createSpyObj "driver", ["on", "subscribe", "unsubscribe"]
        @logger = jasmine.createSpyObj "logger", ["debug"]
        @subject = new Subscriber @driver, @logger

        @driver.subscribe.andCallFake -> bluebird.resolve()
        @driver.unsubscribe.andCallFake -> bluebird.resolve()

        @error = new Error "You done goofed."

    it "stores the supplied dependencies", ->
        expect(@subject.driver).toBe @driver
        expect(@subject.logger).toBe @logger

    it "creates sensible default dependencies", ->
        @subject = new Subscriber @driver

        expect(@subject.logger).toBe winston

    describe "create()", ->

        it "creates subscriptions correctly", ->
            actual = @subject.create "topic-a"

            expect(actual.constructor.name).toBe "Subscription"
            expect(actual.subscriber).toBe @subject
            expect(actual.topic).toBe "topic-a"

    describe "subscribe()", ->

        it "subscribes to the correct topic", (done) ->
            bluebird.join \
                @subject.subscribe("topic-a"),
                @subject.subscribe("topic-b"),
                =>
                    expect(@driver.subscribe).toHaveBeenCalledWith "topic-a"
                    expect(@driver.subscribe).toHaveBeenCalledWith "topic-b"
                    expect(@subject._topic("topic-a").state).toBe "subscribed"
                    expect(@subject._topic("topic-b").state).toBe "subscribed"
                    done()

        it "only subscribes once per topic when called synchronously", (done) ->
            bluebird.join \
                @subject.subscribe("topic-a"),
                @subject.subscribe("topic-a"),
                =>
                    expect(@driver.subscribe.calls.length).toBe 1
                    done()

        it "only subscribes once per topic when called asynchronously", (done) ->
            @subject.subscribe("topic-a")

            @subject.subscribe("topic-a").then =>
                expect(@driver.subscribe.calls.length).toBe 1
                done()

        it "can subscribe immediately after unsubscribing", (done) ->
            @subject.subscribe("topic-a")
            @subject.unsubscribe("topic-a")

            @subject.subscribe("topic-a").then =>
                expect(@subject._topic("topic-a").state).toBe "subscribed"
                done()

        it "logs the details", (done) ->
            @subject.subscribe("topic-a").then =>
                expect(@logger.debug).toHaveBeenCalledWith 'Subscribed to topic "{topic}"', topic: "topic-a"
                done()

        it "propagates subscription errors", (done) ->
            @driver.subscribe.andCallFake => bluebird.reject @error

            @subject.subscribe("topic-a").catch (error) =>
                expect(error).toBe @error
                done()

    describe "unsubscribe()", ->

        it "unsubscribes from the correct topic", (done) ->
            bluebird.join \
                @subject.subscribe("topic-a"),
                @subject.subscribe("topic-b"),
                @subject.unsubscribe("topic-a"),
                @subject.unsubscribe("topic-b"),
                =>
                    expect(@driver.unsubscribe).toHaveBeenCalledWith "topic-a"
                    expect(@driver.unsubscribe).toHaveBeenCalledWith "topic-b"
                    expect(@subject._topic("topic-a").state).toBe "unsubscribed"
                    expect(@subject._topic("topic-b").state).toBe "unsubscribed"
                    done()

        it "only unsubscribes when appropriate, when called synchronously", (done) ->
            @subject.subscribe("topic-a")
            .then => @subject.subscribe("topic-a")
            .then => @subject.unsubscribe("topic-a")
            .then => @subject.unsubscribe("topic-a")
            .then =>
                expect(@driver.unsubscribe.calls.length).toBe 1
                done()

        it "only unsubscribes when appropriate, when called asynchronously", (done) ->
            @subject.subscribe("topic-a")
            @subject.subscribe("topic-a")
            @subject.unsubscribe("topic-a")

            @subject.unsubscribe("topic-a").then =>
                expect(@driver.unsubscribe.calls.length).toBe 1
                done()

        it "does nothing when already unsubscribed", (done) ->
            @subject.unsubscribe("topic-a").then =>
                expect(@driver.unsubscribe.calls.length).toBe 0
                done()

        it "logs the details", (done) ->
            @subject.subscribe("topic-a")

            @subject.unsubscribe("topic-a").then =>
                expect(@logger.debug).toHaveBeenCalledWith 'Unsubscribed from topic "{topic}"', topic: "topic-a"
                done()

        it "propagates unsubscription errors", (done) ->
            @driver.unsubscribe.andCallFake => bluebird.reject @error
            @subject.subscribe("topic-a")

            @subject.unsubscribe("topic-a").catch (error) =>
                expect(error).toBe @error
                done()

    describe "_message()", ->

        it "emits generic message events", (done) ->
            @subject.on "message", (topic, payload) ->
                expect(topic).toBe "topic-a"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._message "topic-a", a: "b", c: "d"

        it "emits message events by topic", (done) ->
            @subject.on "message.topic-a", (topic, payload) ->
                expect(topic).toBe "topic-a"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._message "topic-a", a: "b", c: "d"

        it 'emits message events to "?" wildcard handler', (done) ->
            @subject.on "message.foo.?", (topic, payload) ->
                expect(topic).toBe "foo.bar"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._message "foo.bar", a: "b", c: "d"

        it 'does not emit message events to non-matching "?" wildcard handler', ->
            handler = jasmine.createSpy()
            @subject.on "message.foo.?", handler
            @subject._message "foo", a: "b", c: "d"

            expect(handler.calls.length).toBe 0

        it 'emits message events to "*" wildcard handler', (done) ->
            @subject.on "message.foo.*", (topic, payload) ->
                expect(topic).toBe "foo.bar.baz"
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._message "foo.bar.baz", a: "b", c: "d"

        it 'does not emit message events to non-matching "*" wildcard handler', ->
            handler = jasmine.createSpy()
            @subject.on "message.*.spam", handler
            @subject._message "foo.bar.baz", a: "b", c: "d"

            expect(handler.calls.length).toBe 0

        it "can still emit wildcard messages after handler is removed", ->
            pattern = "message.foo.?"
            handler1 = jasmine.createSpy()
            handler2 = jasmine.createSpy()

            @subject.on pattern, handler1
            @subject.on pattern, handler2
            @subject.removeListener pattern, handler1

            @subject._message "foo.bar", a: "b", c: "d"

            expect(handler1.calls.length).toBe 0
            expect(handler2.calls.length).toBe 1

        it "removes regexes when there are no wildcard handlers", (done) ->
            pattern = "message.foo.?"
            handler1 = ->
            handler2 = ->

            @subject.on pattern, handler1
            @subject.on pattern, handler2

            expect(@subject._wildcardListeners[pattern]).toBeDefined()

            @subject.removeListener pattern, handler1
            @subject.removeListener pattern, handler2

            expect(@subject._wildcardListeners[pattern]).toBeUndefined()
            done()

        it "logs the details", (done) ->
            @subject.subscribe("topic-name")
            .then =>
                @logger.debug.andCallFake (message, meta) ->
                    expect(message).toBe 'Received {payload} from topic "{topic}"'
                    expect(meta).toEqual
                        topic: "topic-a"
                        payload: '{"a":"b","c":"d"}'
                    done()
            .then =>
                @subject._message "topic-a", a: "b", c: "d"
