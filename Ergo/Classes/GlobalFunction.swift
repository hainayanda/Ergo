//
//  GlobalFunction.swift
//  Ergo
//
//  Created by Nayanda Haberty on 01/07/21.
//

import Foundation

/// Perform task in given dispatcher. If current queue is same as given dispatcher, it will run synchronously.
/// - Parameters:
///   - dispatcher: DispatchQueue where task run
///   - work: Task to run
public func syncIfPossible(on dispatcher: DispatchQueue, execute work: @escaping () -> Void) {
    let currentQueue: DispatchQueue = .current ?? .main
    guard currentQueue == dispatcher else {
        dispatcher.async(execute: work)
        return
    }
    work()
}

/// Perform task in main DispatchQueue. If current queue is main, it will run synchronously.
/// - Parameter work: Task to run
public func syncOnMainIfPossible(execute work: @escaping () -> Void) {
    syncIfPossible(on: .main, execute: work)
}

@discardableResult
/// Perform task as a promise in given dispatcher
/// - Parameters:
///   - dispatcher: DispatchQueue where task run, the default is global background
///   - work: Task to run
/// - Returns: Promise of Result
public func runPromise<Result>(on dispatcher: DispatchQueue = .global(qos: .background), run work: @escaping () throws -> Result) -> Promise<Result> {
    asyncPromise(on: dispatcher) { done in
        do {
            done(try work(), nil)
        } catch {
            done(nil, error)
        }
    }
}

@discardableResult
/// Perform Task as a promise in main dispatcher
/// - Parameter work: Task to run
/// - Returns: Promise of Result
public func runPromiseOnMain<Result>(run work: @escaping () -> Result) -> Promise<Result> {
    runPromise(on: .main, run: work)
}

/// Perform async task as a promise in given dispatcher
/// - Parameters:
///   - dispatcher: DispatchQueue where task run, the default is global background
///   - work: Promise task. Parameter is closure with Result and Error, call it once when the task is done, it will then trigger next Promise
/// - Returns: Promise of Result
public func asyncPromise<Result>(on dispatcher: DispatchQueue = .global(qos: .background), run work: @escaping AsyncPromiseWorker<Result>) -> Promise<Result> {
    let promise: ClosurePromise<Result> = .init(currentQueue: dispatcher, worker: work)
    return promise
}

/// Perform async task as a promise in given dispatcher
/// - Parameter work: Promise task. Parameter is closure with Result and Error, call it once when the task is done, it will then trigger next Promise
/// - Returns: Promise of Result
public func asyncPromiseOnMain<Result>(run work: @escaping AsyncPromiseWorker<Result>) -> Promise<Result> {
    asyncPromise(on: .main, run: work)
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
/// Perform async await from swift 5.5 task as a promise
/// - Parameter asyncWork: Async task. Closure that contains awaitable call
/// - Returns: Promise of Result
public func asyncAwaitPromise<Result>(asyncWork: @Sendable @escaping () async throws -> Result) -> Promise<Result> {
    let promise: ClosurePromise<Result> = .init(worker: asyncWork)
    return promise
}

/// Create promise that wait 2 promise to finished and combine its results
/// - Parameters:
///   - task1: First Promise
///   - task2: Second Promise
/// - Returns: Promise of combined results
public func waitPromises<Result1, Result2>(
    from task1: Promise<Result1>,
    _ task2: Promise<Result2>) -> Promise<(Result1, Result2)> {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            return asyncAwaitPromise {
                let result1 = try await task1.result
                let result2 = try await task2.result
                return (result1, result2)
            }
        }
        let currentQueue: DispatchQueue = .current ?? .main
        let promise: Promise<(Result1, Result2)> = .init(currentQueue: currentQueue)
        var retainedResult1: Result1?
        var retainedResult2: Result2?
        var retainedError: Error?
        defer {
            task1.finally { result, error in
                retainedResult1 = result
                retainedError = error
                if let result1 = result, let result2 = retainedResult2 {
                    promise.currentValue = (result1, result2)
                } else if let errorHappens = error ?? retainedError {
                    promise.drop(becauseOf: errorHappens)
                }
            }
            task2.finally { result, error in
                retainedResult2 = result
                retainedError = error
                if let result2 = result, let result1 = retainedResult1 {
                    promise.currentValue = (result1, result2)
                } else if let errorHappens = error ?? retainedError {
                    promise.drop(becauseOf: errorHappens)
                }
            }
        }
        return promise
    }

/// Create promise that wait 3 promise to finished and combine its results
/// - Parameters:
///   - task1: First Promise
///   - task2: Second Promise
///   - task3: Third Promise
/// - Returns: Promise of combined results
public func waitPromises<Result1, Result2, Result3>(
    from task1: Promise<Result1>,
    _ task2: Promise<Result2>,
    _ task3: Promise<Result3>) -> Promise<(Result1, Result2, Result3)> {
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            return asyncAwaitPromise {
                let result1 = try await task1.result
                let result2 = try await task2.result
                let result3 = try await task3.result
                return (result1, result2, result3)
            }
        }
        let currentQueue: DispatchQueue = .current ?? .main
        let promise: Promise<(Result1, Result2, Result3)> = .init(currentQueue: currentQueue)
        var retainedResult1: Result1?
        var retainedResult2: Result2?
        var retainedResult3: Result3?
        var retainedError: Error?
        defer {
            task1.finally { result, error in
                retainedResult1 = result
                retainedError = error
                if let result1 = result, let result2 = retainedResult2, let result3 = retainedResult3 {
                    promise.currentValue = (result1, result2, result3)
                } else if let errorHappens = error ?? retainedError {
                    promise.drop(becauseOf: errorHappens)
                }
            }
            task2.finally { result, error in
                retainedResult2 = result
                retainedError = error
                if let result2 = result, let result1 = retainedResult1, let result3 = retainedResult3 {
                    promise.currentValue = (result1, result2, result3)
                } else if let errorHappens = error ?? retainedError {
                    promise.drop(becauseOf: errorHappens)
                }
            }
            task3.finally { result, error in
                retainedResult3 = result
                retainedError = error
                if let result3 = result, let result1 = retainedResult1, let result2 = retainedResult2 {
                    promise.currentValue = (result1, result2, result3)
                } else if let errorHappens = error ?? retainedError {
                    promise.drop(becauseOf: errorHappens)
                }
            }
        }
        return promise
    }
