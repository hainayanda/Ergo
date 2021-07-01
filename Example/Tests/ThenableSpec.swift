//
//  ThenableSpec.swift
//  Ergo_Tests
//
//  Created by Nayanda Haberty on 01/07/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Ergo

class ThenableSpec: QuickSpec {
    override func spec() {
        describe("thenable") {
            it("should run on current queue") {
                let currentQueue: DispatchQueue = .current ?? .main
                var promiseQueue: DispatchQueue? = nil
                runPromise {
                    promiseQueue = .current
                }
                expect(promiseQueue).toEventually(equal(currentQueue))
            }
            it("should run linearly") {
                var counter = 0
                var firstCounter = -1
                var secondCounter = -1
                var thirdCounter = -1
                var finallyCounter = -1
                let thenable = runPromise { () -> Bool in
                    counter += 1
                    firstCounter = counter
                    return true
                }.then { param -> Bool in
                    expect(param).to(beTrue())
                    counter += 1
                    secondCounter = counter
                    return false
                }.then { param -> Bool in
                    expect(param).to(beFalse())
                    counter += 1
                    thirdCounter = counter
                    return true
                }.finally { param, error in
                    expect(param).to(beTrue())
                    expect(error).to(beNil())
                    counter += 1
                    finallyCounter = counter
                }
                expect(thenable.isCompleted).toEventually(beTrue())
                expect(counter).toEventually(equal(4))
                expect(firstCounter).toEventually(equal(1))
                expect(secondCounter).toEventually(equal(2))
                expect(thirdCounter).toEventually(equal(3))
                expect(finallyCounter).toEventually(equal(4))
            }
            it("should run linearly on changing thread") {
                var counter = 0
                var firstCounter = -1
                var secondCounter = -1
                var thirdCounter = -1
                var finallyCounter = -1
                let thenable = runPromise(on: .main) { () -> Bool in
                    expect(DispatchQueue.current).to(equal(.main))
                    counter += 1
                    firstCounter = counter
                    return true
                }.then(on: .global(qos: .background)) { param -> Bool in
                    expect(DispatchQueue.current).to(equal(DispatchQueue.global(qos: .background)))
                    expect(param).to(beTrue())
                    counter += 1
                    secondCounter = counter
                    return false
                }.then(on: .global(qos: .utility)) { param -> Bool in
                    expect(DispatchQueue.current).to(equal(DispatchQueue.global(qos: .utility)))
                    expect(param).to(beFalse())
                    counter += 1
                    thirdCounter = counter
                    return true
                }.finally { param, error in
                    expect(DispatchQueue.current).to(equal(DispatchQueue.global(qos: .utility)))
                    expect(param).to(beTrue())
                    expect(error).to(beNil())
                    counter += 1
                    finallyCounter = counter
                }
                expect(thenable.isCompleted).toEventually(beTrue())
                expect(counter).toEventually(equal(4))
                expect(firstCounter).toEventually(equal(1))
                expect(secondCounter).toEventually(equal(2))
                expect(thirdCounter).toEventually(equal(3))
                expect(finallyCounter).toEventually(equal(4))
            }
            it("should wait 2 thenables") {
                var results: (Int, Int)?
                var finallyCalled: Bool = false
                let thenable1 = runPromise(on: .global(qos: .background)) {
                    1
                }
                let thenable2 = runPromise(on: .global(qos: .utility)) {
                    2
                }
                let waitThenable = waitPromises(from: thenable1, thenable2)
                    .then(on: .main) { waitedResults in
                        results = waitedResults
                    }.finally { error in
                        expect(error).to(beNil())
                        finallyCalled = true
                    }
                expect(finallyCalled).toEventually(beTrue())
                expect(waitThenable.isCompleted).toEventually(beTrue())
                expect(results?.0).toEventually(equal(1))
                expect(results?.1).toEventually(equal(2))
            }
            it("should wait 3 thenables") {
                var results: (Int, Int, Int)?
                var finallyCalled: Bool = false
                let thenable1 = runPromise(on: .global(qos: .background)) {
                    1
                }
                let thenable2 = runPromise(on: .global(qos: .utility)) {
                    2
                }
                let thenable3 = runPromise(on: .global(qos: .userInitiated)) {
                    3
                }
                let waitThenable = waitPromises(from: thenable1, thenable2, thenable3)
                    .then(on: .main) { waitedResults in
                        results = waitedResults
                    }.finally { error in
                        expect(error).to(beNil())
                        finallyCalled = true
                    }
                expect(finallyCalled).toEventually(beTrue())
                expect(waitThenable.isCompleted).toEventually(beTrue())
                expect(results?.0).toEventually(equal(1))
                expect(results?.1).toEventually(equal(2))
                expect(results?.2).toEventually(equal(3))
            }
            it("should run finally even tho have an error") {
                let error = NSError(domain: "test", code: 1, userInfo: nil)
                var finallyCalled: Bool = false
                runPromise {
                    throw error
                }.finally { catchedError in
                    finallyCalled = true
                    expect(catchedError).toNot(beNil())
                }
                expect(finallyCalled).toEventually(beTrue())
            }
            it("should run finally in the end even tho have an error") {
                let error = NSError(domain: "test", code: 1, userInfo: nil)
                var counter = 0
                var firstCounter = -1
                var secondCounter = -1
                var thirdCounter = -1
                var finallyCounter = -1
                let thenable = runPromise {
                    counter += 1
                    firstCounter = counter
                }.then {
                    counter += 1
                    secondCounter = counter
                    throw error
                }.then {
                    counter += 1
                    thirdCounter = counter
                }.finally { error in
                    expect(error).toNot(beNil())
                    counter += 1
                    finallyCounter = counter
                }
                expect(thenable.isCompleted).toEventually(beTrue())
                expect(counter).toEventually(equal(3))
                expect(firstCounter).toEventually(equal(1))
                expect(secondCounter).toEventually(equal(2))
                expect(thirdCounter).toEventually(equal(-1))
                expect(finallyCounter).toEventually(equal(3))
            }
        }
    }
}
