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

        @error = new Error "You done goofed."

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

        it "can subscribe after a failed subscription", (done) ->
            @subscriber.subscribe.andCallFake => bluebird.reject @error

            @subject.enable().catch =>
                @subscriber.subscribe.andCallFake -> bluebird.resolve()

                @subject.enable().then =>
                    expect(@subject._state.isOn).toBe true
                    done()

    describe "disable()", ->

        it "unsubscribes from the correct topic", (done) ->
            @subject.enable()

            @subject.disable().then =>
                expect(@subscriber.unsubscribe).toHaveBeenCalledWith @topic
                done()

        it "removes the appropriate message listeners", (done) ->
            @subject.enable()

            @subject.disable().then =>
                expect(@subscriber.removeListener).toHaveBeenCalledWith "message.#{@topic}", @subject._message
                done()

        it "only unsubscribes once when called sequentially", (done) ->
            @subject.enable()
            @subject.disable()
            .then =>
                @subject.disable()
            .then =>
                expect(@subscriber.unsubscribe.calls.length).toBe 1
                done()

        it "only unsubscribes once when called concurrently", (done) ->
            @subject.enable()
            @subject.disable()

            @subject.disable().then =>
                expect(@subscriber.unsubscribe.calls.length).toBe 1
                done()

        it "can unsubscribe after a failed unsubscription", (done) ->
            @subscriber.unsubscribe.andCallFake => bluebird.reject @error
            @subject.enable()

            @subject.disable().catch =>
                @subscriber.unsubscribe.andCallFake -> bluebird.resolve()

                @subject.disable().then =>
                    expect(@subject._state.isOn).toBe false
                    done()

    describe "_message()", ->

        it "proxies message events", (done) ->
            @subject.on "message", (topic, payload) =>
                expect(topic).toBe @topic
                expect(payload).toEqual a: "b", c: "d"
                done()

            @subject._message @topic, a: "b", c: "d"
