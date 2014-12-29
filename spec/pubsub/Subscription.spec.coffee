bluebird = require "bluebird"
requireHelper = require "../require-helper"
Subscription = requireHelper "pubsub/Subscription"

describe "pubsub.Subscription", ->

    beforeEach ->
        @subscriber = jasmine.createSpyObj "subscriber", ["on", "removeListener", "subscribe", "unsubscribe"]
        @topic = "topic-a"
        @subject = new Subscription @subscriber, @topic

        @subscriber.subscribe.andCallFake -> bluebird.resolve()
        @subscriber.unsubscribe.andCallFake -> bluebird.resolve()

    it "stores the supplied dependencies", ->
        expect(@subject.subscriber).toBe @subscriber
        expect(@subject.topic).toBe @topic

    describe "enable()", ->

        it "subscribes to the correct topic", (done) ->
            @subject.enable().then =>
                expect(@subscriber.subscribe).toHaveBeenCalledWith @topic
                done()

        it "listens for the correct message events", (done) ->
            @subject.enable().then =>
                expect(@subscriber.on).toHaveBeenCalledWith "message.#{@topic}", @subject._message
                done()

        it "only subscribes once when called sequentially", (done) ->
            @subject.enable()
            .then =>
                @subject.enable()
            .then =>
                expect(@subscriber.subscribe.calls.length).toBe 1
                done()

        it "only subscribes once when called concurrently", (done) ->
            @subject.enable()

            @subject.enable().then =>
                expect(@subscriber.subscribe.calls.length).toBe 1
                done()
