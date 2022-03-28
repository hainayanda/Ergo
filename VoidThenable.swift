//
//  VoidThenable.swift
//  Ergo
//
//  Created by Nayanda Haberty on 28/03/22.
//

import Foundation

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

public extension Thenable where Result == (Void, Void) {
    
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
        _ = try await result
    }
    
}

public extension Thenable where Result == (Void, Void, Void) {
    
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
        _ = try await result
    }
    
}
