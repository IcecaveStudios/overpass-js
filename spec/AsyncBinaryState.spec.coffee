bluebird = require "bluebird"
requireHelper = require "./require-helper"
AsyncBinaryState = requireHelper "AsyncBinaryState"

describe "AsyncBinaryState", ->

    beforeEach ->
        @subject = new AsyncBinaryState()

        @error = new Error "You done goofed."

    describe "constructor()", ->

        it "defaults to off as the inital state", ->
            expect(@subject.isOn).toBe false

        it "accepts initial state as an argument", ->
            @subject = new AsyncBinaryState true

            expect(@subject.isOn).toBe true

    describe "setOn", ->

        it "sets the state to on", (done) ->
            @subject.setOn().then =>
                expect(@subject.isOn).toBe true
                done()

        it "calls supplied handler functions", (done) ->
            handler = jasmine.createSpy()

            @subject.setOn(handler).then =>
                expect(handler).toHaveBeenCalled()
                done()

    describe "setOff", ->

        beforeEach (done) ->
            @subject.setOn().then => done()

        it "sets the state to off", (done) ->
            @subject.setOff().then =>
                expect(@subject.isOn).toBe false
                done()

        it "calls supplied handler functions", (done) ->
            handler = jasmine.createSpy()

            @subject.setOff(handler).then =>
                expect(handler).toHaveBeenCalled()
                done()

    describe "set", ->

        it "sets the state to the supplied value", (done) ->
            @subject.set(true).then =>
                expect(@subject.isOn).toBe true
                done()

        it "calls supplied handler functions when the state is changing", (done) ->
            handler = jasmine.createSpy()

            @subject.set(true, handler).then =>
                expect(handler).toHaveBeenCalled()
                done()

        it "does not call the supplied handler functions unless the state is changing", (done) ->
            handler = jasmine.createSpy()

            @subject.set(false, handler).then =>
                expect(handler).not.toHaveBeenCalled()
                done()

        it "supports handlers that return a promise", (done) ->
            handler = => bluebird.resolve "a"

            @subject.set(true, handler).then (result) =>
                expect(result).toBe "a"
                done()

        it "does not set the state if the handler returns a rejected promise", (done) ->
            handler = => bluebird.reject @error

            @subject.set(true, handler).catch (error) =>
                expect(error).toBe @error
                expect(@subject.isOn).toBe false
                done()
