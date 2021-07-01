//
//  ChainAnimatorSpec.swift
//  Ergo_Tests
//
//  Created by Nayanda Haberty on 01/07/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import Quick
import Nimble
import Ergo

class ChainAnimatorSpec: QuickSpec {
    override func spec() {
        describe("chaining animation") {
            var view: UIView!
            beforeEach {
                view = UIView()
            }
            it("should chaining animator") {
                var counter: Int = 0
                var animationCounter1: Int = -1
                var animationCounter2: Int = -1
                var animationCounter3: Int = -1
                var finallyCounter: Int = -1
                let thenable = UIView.chainAnimate(withDuration: 0.1)
                    .animation {
                        view.alpha = .zero
                        counter += 1
                        animationCounter1 = counter
                    }.chain(withDuration: 0.1)
                    .animation {
                        view.frame.origin.x = 1
                        counter += 1
                        animationCounter2 = counter
                    }.chain(withDuration: 0.1)
                    .animation {
                        view.frame.origin.y = 1
                        counter += 1
                        animationCounter3 = counter
                    }.animate()
                    .then { _ in
                        counter += 1
                        finallyCounter = counter
                    }
                expect(thenable.isCompleted).toEventually(beTrue())
                expect(counter).toEventually(equal(4))
                expect(animationCounter1).toEventually(equal(1))
                expect(view.alpha).toEventually(equal(.zero))
                expect(animationCounter2).toEventually(equal(2))
                expect(view.frame.origin.x).toEventually(equal(1))
                expect(animationCounter3).toEventually(equal(3))
                expect(view.frame.origin.y).toEventually(equal(1))
                expect(finallyCounter).toEventually(equal(4))
            }
        }
    }
}
#endif
