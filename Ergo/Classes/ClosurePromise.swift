//
//  ClosurePromise.swift
//  Ergo
//
//  Created by Nayanda Haberty on 01/07/21.
//

import Foundation
import Chary

public typealias AsyncPromiseWorker<Result> = (PromiseConsumer<Result>) -> Void

public class PromiseConsumer<Result> {
    typealias Resolver = (Result) -> Void
    typealias Rejector = (Error?) -> Void
    
    let resolver: Resolver
    let rejector: Rejector
    @Atomic var valid: Bool = true
    
    init(_ resolving: @escaping Resolver, whenReject rejecting: @escaping Rejector) {
        resolver = resolving
        rejector = rejecting
    }
    
    public func resolve(_ result: Result) {
        runWhenValid {
            resolver(result)
        }
    }
    
    public func reject(_ error: Error?) {
        runWhenValid {
            rejector(error)
        }
    }
    
    func runWhenValid(_ runner: () -> Void) {
        guard valid else {
            fatalError("Promise Consumer can only accept one result")
        }
        valid = false
        runner()
    }
}

extension PromiseConsumer where Result == Void {
    public func resolve() {
        resolve(())
    }
}

/// Promise based on closure
open class ClosurePromise<Result>: Promise<Result> {
    public typealias Worker = AsyncPromiseWorker<Result>
    
    /// Default initializer
    /// - Parameters:
    ///   - currentQueue: DispatchQueue where worker run
    ///   - worker: Promise task. Parameter is closure with Result and Error, call it once when the task is done, it will then trigger next Promise
    public init(currentQueue: DispatchQueue? = nil, timeout: TimeInterval = 10, worker: @escaping Worker) {
        super.init(currentQueue: currentQueue)
        // promise retained by design
        @Atomic var promise: ClosurePromise<Result>? = self
        self.promiseQueue.asyncIfNeeded {
            worker(.init { result in
                promise?.currentValue = result
                promise = nil
            } whenReject: { error in
                promise?.drop(
                    becauseOf: error ?? ErgoError(
                        errorDescription: "Ergo Error: Invalid result",
                        failureReason: "result is nil"
                    )
                )
                promise = nil
            })
        }
        promiseQueue.asyncAfter(deadline: .now() + timeout) {
            guard !(promise?.isCompleted ?? true) else { return }
            promise?.drop(
                becauseOf: ErgoError(
                    errorDescription: "Ergo Error: Timeout",
                    failureReason: "no result after \(timeout) second"
                )
            )
            promise = nil
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public init(worker: @Sendable @escaping () async throws -> Result) {
        super.init(currentQueue: nil)
        // promise retained by design
        let promise = self
        Task {
            do {
                let result = try await worker()
                promise.currentValue = result
            } catch {
                promise.drop(becauseOf: error)
            }
        }
    }
    
    @discardableResult
    /// Perform task that will executed after previous task
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    ///   - execute: Task to execute
    /// - Returns: Promise of next result
    open override func then<NextResult>(on dispatcher: DispatchQueue, do execute: @escaping (Result) throws -> NextResult) -> Promise<NextResult> {
        super.then(on: dispatcher, do: execute)
    }
    
    /// Perform task that will executed after previous task and return a promise
    /// - Parameters:
    ///   - createNewPromise: Task that will execute and producing new promise
    ///   - dispatcher: Dispatcher where the task will executed
    /// - Returns: new promise
    open override func thenContinue<NextResult>(on dispatcher: DispatchQueue, with createNewPromise: @escaping (Result) throws -> Promise<NextResult>) -> Promise<NextResult> {
        super.thenContinue(on: dispatcher, with: createNewPromise)
    }
    
    @discardableResult
    /// Handle error if occurs in previous task
    /// - Parameter handling: Error handler
    /// - Returns: current Promise
    open override func handle(_ handling: @escaping (Error) -> Void) -> Promise<Result> {
        super.handle(handling)
    }
    
    @discardableResult
    /// Perform task after all previous task is finished
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    /// - Parameter execute: Task to execute
    /// - Returns: New void promise
    open override func finally(on dispatcher: DispatchQueue, do execute: @escaping FinallyConsumer<Result>) -> VoidPromise {
        super.finally(on: dispatcher, do: execute)
    }
    
    /// Drop task and emit error
    /// - Parameter error: error emitted
    open override func drop(becauseOf error: Error) {
        super.drop(becauseOf: error)
    }
}
