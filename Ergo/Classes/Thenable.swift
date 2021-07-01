//
//  Thenable.swift
//  Nimble
//
//  Created by Nayanda Haberty on 01/07/21.
//

import Foundation

public typealias VoidPromise = Promise<Void>

/// class that can catch an Error
public protocol Dropable: class {
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
    var result: Result? { get }
    /// True if previous task already completed
    var isCompleted: Bool { get }
    /// DispatchQueue from previous task
    var currentQueue: DispatchQueue { get }
    /// Perform task that will executed after previous task
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    ///   - execute: Task to execute
    @discardableResult
    func then<NextResult>(on dispatcher: DispatchQueue, do execute: @escaping (Result) throws -> NextResult) -> Promise<NextResult>
    /// Handle error if occurs in previous task
    /// - Parameter handling: Error handler
    @discardableResult
    func handle(_ handling: @escaping (Error) -> Void) -> Promise<Result>
    /// Perform task after all previous task is finished
    /// - Parameter execute: Task to execute
    @discardableResult
    func finally(do execute: @escaping PromiseConsumer<Result>) -> VoidPromise
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
        if let _: Result = result {
            return true
        } else if error != nil {
            return true
        }
        return false
    }
    
    /// Perform task that will executed after previous task
    /// - Parameter execute: Task to execute
    /// - Returns: Promise of next result
    @discardableResult
    func then<NextResult>(do execute: @escaping (Result) throws -> NextResult) -> Promise<NextResult> {
        then(on: currentQueue, do: execute)
    }
}

public extension Thenable where Result == Void {
    /// Perform task that will executed after previous task
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    ///   - execute: Task to execute
    /// - Returns: Promise of next result
    @discardableResult
    func then<NextResult>(on dispatcher: DispatchQueue, do execute: @escaping () throws -> NextResult) -> Promise<NextResult> {
        then(on: dispatcher) { _ throws -> NextResult in
            try execute()
        }
    }
    
    /// Perform task that will executed after previous task
    /// - Parameter execute: Task to execute
    /// - Returns: Promise of next result
    @discardableResult
    func then<NextResult>(do execute: @escaping () throws -> NextResult) -> Promise<NextResult> {
        then { _ throws -> NextResult in
            try execute()
        }
    }
    
    /// Perform task after all previous task is finished
    /// - Parameter execute: Task to execute
    /// - Returns: Promise with no result
    @discardableResult
    func finally(do execute: @escaping (Error?) -> Void) -> VoidPromise {
        finally { _, error in
            execute(error)
        }
    }
}
