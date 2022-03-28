//
//  Thenable.swift
//  Nimble
//
//  Created by Nayanda Haberty on 01/07/21.
//

import Foundation

public typealias VoidPromise = Promise<Void>

/// class that can catch an Error
public protocol Dropable: AnyObject {
    /// error catched
    var error: Error? { get }
    /// True if error is occurs on previous task
    var isError: Bool { get }
    /// Drop with error
    /// - Parameter error: error
    func drop(becauseOf error: Error)
}

/// protocol to perform thenable task
public protocol Thenable: Dropable {
    associatedtype Result
    /// Result of previous task
    var currentValue: Result? { get }
    /// True if previous task already completed
    var isCompleted: Bool { get }
    /// DispatchQueue from previous task
    var promiseQueue: DispatchQueue { get }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// get result asynchronously
    var result: Result { get async throws }
    
    @discardableResult
    /// Perform task that will executed after previous task
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    ///   - execute: Task to execute
    /// - Returns: New promise
    func then<NextResult>(on dispatcher: DispatchQueue, do execute: @escaping (Result) throws -> NextResult) -> Promise<NextResult>
    
    /// Perform task that will executed after previous task and return a promise
    /// - Parameters:
    ///   - createNewPromise: Task that will execute and producing new promise
    ///   - dispatcher: Dispatcher where the task will executed
    /// - Returns: new promise
    func thenContinue<NextResult>(on dispatcher: DispatchQueue, with createNewPromise: @escaping (Result) throws -> Promise<NextResult>) -> Promise<NextResult>
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Perform task that will executed after previous task and return a promise
    /// - Parameters:
    ///   - asyncTask: async task
    /// - Returns: new promise
    func thenAsyncAwait<NextResult>(_ asyncTask: @Sendable @escaping (Result) async throws -> NextResult) -> Promise<NextResult>
    
    @discardableResult
    /// Handle error if occurs in previous task
    /// - Parameter handling: Error handler
    /// - Returns: New promise
    func handle(_ handling: @escaping (Error) -> Void) -> Promise<Result>
    
    @discardableResult
    /// Perform task after all previous task is finished
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    /// - Parameter execute: Task to execute
    /// - Returns: New void promise
    func finally(on dispatcher: DispatchQueue, do execute: @escaping PromiseConsumer<Result>) -> VoidPromise
}

public extension Dropable {
    /// True if error is occurs on previous task
    var isError: Bool {
        return error != nil
    }
    
    /// drop and emit default error
    func drop() {
        drop(
            becauseOf: ErgoError(
                errorDescription: "Ergo Error: dropping task",
                failureReason: "Manual drop call"
            )
        )
    }
}

public extension Thenable {
    /// True if previous task already completed
    var isCompleted: Bool {
        if let _: Result = currentValue {
            return true
        } else if error != nil {
            return true
        }
        return false
    }
    
    @discardableResult
    /// Perform task that will executed after previous task
    /// - Parameter execute: Task to execute
    /// - Returns: Promise of next result
    func then<NextResult>(do execute: @escaping (Result) throws -> NextResult) -> Promise<NextResult> {
        then(on: promiseQueue, do: execute)
    }
    
    @discardableResult
    /// Perform task that will executed after previous task
    /// - Parameter execute: Task to execute
    /// - Returns: Promise of next result
    func thenContinue<NextResult>(with createNewPromise: @escaping (Result) throws -> Promise<NextResult>) -> Promise<NextResult> {
        thenContinue(on: promiseQueue, with: createNewPromise)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Perform task that will executed after previous task and return a promise
    /// - Parameters:
    ///   - asyncTask: async task
    /// - Returns: new promise
    func thenAsyncAwait<NextResult>(_ asyncTask: @Sendable @escaping (Result) async throws -> NextResult) -> Promise<NextResult> {
        thenContinue { result in
            return ClosurePromise {
                try await asyncTask(result)
            }
        }
    }
    
    @discardableResult
    /// Perform task after all previous task is finished
    /// - Parameter execute: Task to execute
    /// - Returns: New void promise
    func finally(do execute: @escaping PromiseConsumer<Result>) -> VoidPromise {
        finally(on: promiseQueue, do: execute)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// Convert Promise to Task
    /// - Returns: Task
    func asTask() -> Task<Result, Error> {
        let promise = self
        return Task<Result, Error> {
            try await promise.result
        }
    }
}

public extension Thenable where Result == Void {
    
    @discardableResult
    /// Perform task that will executed after previous task
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    ///   - execute: Task to execute
    /// - Returns: Promise of next result
    func then<NextResult>(on dispatcher: DispatchQueue, do execute: @escaping () throws -> NextResult) -> Promise<NextResult> {
        then(on: dispatcher) { _ throws -> NextResult in
            try execute()
        }
    }
    
    @discardableResult
    /// Perform task that will executed after previous task
    /// - Parameter execute: Task to execute
    /// - Returns: Promise of next result
    func then<NextResult>(do execute: @escaping () throws -> NextResult) -> Promise<NextResult> {
        then { _ throws -> NextResult in
            try execute()
        }
    }
    
    @discardableResult
    /// Perform task after all previous task is finished
    /// - Parameter execute: Task to execute
    /// - Returns: Promise with no result
    func finally(do execute: @escaping (Error?) -> Void) -> VoidPromise {
        finally { _, error in
            execute(error)
        }
    }
    
    @discardableResult
    /// Perform task after all previous task is finished
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    /// - Parameter execute: Task to execute
    /// - Returns: New void promise
    func finally(on dispatcher: DispatchQueue, do execute: @escaping (Error?) -> Void) -> VoidPromise {
        finally(on: dispatcher) { _, error in
            execute(error)
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// async method that will wait until promise is completed
    func waitUntilCompleted() async throws {
        try await result
    }
    
}
