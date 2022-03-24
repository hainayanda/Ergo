//
//  NestedPromise.swift
//  Ergo
//
//  Created by Nayanda Haberty on 24/03/22.
//

import Foundation

/// Regular Promise
open class NestedPromise<Result>: Promise<Result> {
    
    var nested: Promise<Result>? {
        didSet {
            guard let nested = nested else {
                return
            }
            listenOrDropIfNeeded(for: nested)
        }
    }
    
    /// Drop task and emit error
    /// - Parameter error: error emitted
    public override func drop(becauseOf error: Error) {
        guard let nested = nested else {
            super.drop(becauseOf: error)
            return
        }
        nested.drop(becauseOf: error)
    }
    
    func listenOrDropIfNeeded(for nested: Promise<Result>) {
        if let error = self.error {
            nested.drop(becauseOf: error)
            return
        }
        let promise = self
        nested.then { result in
            promise.currentValue = result
        }.handle { error in
            promise.error = error
        }
    }
}
