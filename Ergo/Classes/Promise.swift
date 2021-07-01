//
//  Promise.swift
//  Ergo
//
//  Created by Nayanda Haberty on 01/07/21.
//

import Foundation

/// Regular Promise
open class Promise<Result>: Thenable {
    
    private var _result: Result?
    /// Result of previous task
    open internal(set) var result: Result? {
        get {
            locked { _result }
        }
        set {
            locked { _result = newValue }
            guard let value: Result = newValue else { return }
            notifyWorker(with: value)
        }
    }
    private var _error: Error?
    /// error catched
    open internal(set) var error: Error? {
        get {
            locked { _error }
        }
        set {
            locked { _error = newValue }
            guard let value: Error = newValue else { return }
            notifyError(value)
        }
    }
    /// DispatchQueue from previous task
    public let currentQueue: DispatchQueue
    var lock: NSLock = NSLock()
    private var workers: [(Result) -> Void] = []
    private var handlers: [(Error) -> Void] = []
    private var child: [Dropable] = []
    
    /// Default initializer
    /// - Parameter currentQueue: current DispatchQueue
    public init(currentQueue: DispatchQueue? = nil) {
        let current: DispatchQueue = .current ?? .main
        self.currentQueue = currentQueue ?? current
    }
    
    /// Perform task that will executed after previous task
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    ///   - execute: Task to execute
    /// - Returns: Promise of next result
    @discardableResult
    open func then<NextResult>(on dispatcher: DispatchQueue, do execute: @escaping (Result) throws -> NextResult) -> Promise<NextResult> {
        let promise: Promise<NextResult> = .init(currentQueue: dispatcher)
        defer {
            registerChild(promise)
            registerWorker { input in
                syncIfPossible(on: dispatcher) {
                    do {
                        let result = try execute(input)
                        promise.result = result
                    } catch {
                        promise.drop(becauseOf: error)
                    }
                }
            }
        }
        return promise
    }
    
    /// Handle error if occurs in previous task
    /// - Parameter handling: Error handler
    /// - Returns: current Promise
    @discardableResult
    open func handle(_ handling: @escaping (Error) -> Void) -> Promise<Result> {
        registerHandler(handling)
        return self
    }
    
    /// Perform task after all previous task is finished
    /// - Parameter execute: Task to execute
    /// - Returns: Promise with no result
    @discardableResult
    open func finally(do execute: @escaping PromiseConsumer<Result>) -> VoidPromise {
        then { result in
            execute(result, nil)
        }.handle { error in
            execute(nil, error)
        }
    }
    
    /// Drop task and emit error
    /// - Parameter error: error emitted
    public func drop(becauseOf error: Error) {
        self.error = error
    }
    
    func registerWorker(_ worker: @escaping (Result) -> Void) {
        guard let result: Result = self.result else {
            locked {
                workers.append(worker)
            }
            return
        }
        worker(result)
    }
    
    func registerChild(_ promise: Dropable) {
        guard let error: Error = self.error else {
            locked {
                child.append(promise)
            }
            return
        }
        promise.drop(becauseOf: error)
    }
    
    func registerHandler(_ handler: @escaping (Error) -> Void) {
        guard let error: Error = self.error else {
            locked {
                handlers.append(handler)
            }
            return
        }
        handler(error)
    }
    
    func notifyError(_ error: Error) {
        notifyHandlers(with: error)
        notifyChild(with: error)
    }
    
    func notifyWorker(with result: Result) {
        dequeueWorkers().forEach { worker in
            worker(result)
        }
    }
    
    func notifyChild(with error: Error) {
        dequeueChild().forEach { child in
            child.drop(becauseOf: error)
        }
    }
    
    func notifyHandlers(with error: Error) {
        dequeueHandlers().forEach { handler in
            handler(error)
        }
    }
    
    func dequeueWorkers() -> [(Result) -> Void] {
        locked {
            let workers = self.workers
            self.workers = []
            return workers
        }
    }
    
    func dequeueChild() -> [Dropable] {
        locked {
            let child = self.child
            self.child = []
            return child
        }
    }
    
    func dequeueHandlers() -> [(Error) -> Void] {
        locked {
            let handlers = self.handlers
            self.handlers = []
            return handlers
        }
    }
    
    func locked<Result>(run: () -> Result) -> Result {
        lock.lock()
        defer {
            lock.unlock()
        }
        return run()
    }
}
