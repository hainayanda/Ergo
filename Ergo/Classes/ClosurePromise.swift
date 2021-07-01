//
//  ClosurePromise.swift
//  Ergo
//
//  Created by Nayanda Haberty on 01/07/21.
//

import Foundation

public typealias PromiseConsumer<Result> = (Result?, Error?) -> Void
public typealias AsyncPromiseWorker<Result> = (@escaping PromiseConsumer<Result>) -> Void

/// Promise based on closure
open class ClosurePromise<Result>: Promise<Result> {
    public typealias Worker = AsyncPromiseWorker<Result>
    
    /// Default initializer
    /// - Parameters:
    ///   - currentQueue: DispatchQueue where worker run
    ///   - worker: Promise task. Parameter is closure with Result and Error, call it once when the task is done, it will then trigger next Promise
    public init(currentQueue: DispatchQueue? = nil, worker: @escaping Worker) {
        super.init(currentQueue: currentQueue)
        // promise retained by design
        let promise = self
        syncIfPossible(on: self.currentQueue) {
            worker { result, error in
                guard let result: Result = result else {
                    promise.drop(
                        becauseOf: error ?? ErgoError(
                            errorDescription: "Ergo Error: Invalid result",
                            failureReason: "result is nil"
                        )
                    )
                    return
                }
                promise.result = result
            }
        }
    }
}
