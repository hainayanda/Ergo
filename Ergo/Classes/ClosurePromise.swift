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
    
    /// Perform task that will executed after previous task
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    ///   - execute: Task to execute
    /// - Returns: Promise of next result
    @discardableResult
    open override func then<NextResult>(on dispatcher: DispatchQueue, do execute: @escaping (Result) throws -> NextResult) -> Promise<NextResult> {
        super.then(on: dispatcher, do: execute)
    }
    
    /// Handle error if occurs in previous task
    /// - Parameter handling: Error handler
    /// - Returns: current Promise
    @discardableResult
    open override func handle(_ handling: @escaping (Error) -> Void) -> Promise<Result> {
        super.handle(handling)
    }
    
    /// Perform task after all previous task is finished
    /// - Parameter execute: Task to execute
    /// - Returns: Promise with no result
    @discardableResult
    open override func finally(do execute: @escaping PromiseConsumer<Result>) -> VoidPromise {
        super.finally(do: execute)
    }
    
    /// Drop task and emit error
    /// - Parameter error: error emitted
    open override func drop(becauseOf error: Error) {
        super.drop(becauseOf: error)
    }
}
