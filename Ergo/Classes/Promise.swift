//
//  Promise.swift
//  Ergo
//
//  Created by Nayanda Haberty on 01/07/21.
//

import Foundation

/// Regular Promise
open class Promise<Result>: Thenable {
    
    private var _currentValue: Result?
    /// Result of previous task
    open internal(set) var currentValue: Result? {
        get {
            locked { _currentValue }
        }
        set {
            locked { _currentValue = newValue }
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
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    /// get result asynchronously
    public var result: Result {
        get async throws {
            let promise = self
            return try await withCheckedThrowingContinuation { continuation in
                promise.register(continuation: continuation)
            }
        }
    }
    
    /// DispatchQueue from previous task
    public let promiseQueue: DispatchQueue
    var lock: NSLock = NSLock()
    private var abstractContinuations: [Any] = []
    private var workers: [(Result) -> Void] = []
    private var handlers: [(Error) -> Void] = []
    private var child: [Dropable] = []
    
    /// Default initializer
    /// - Parameter currentQueue: current DispatchQueue
    public init(currentQueue: DispatchQueue? = nil) {
        let current: DispatchQueue = .current ?? .main
        let queueUsed = currentQueue ?? current
        self.promiseQueue = queueUsed
        DispatchQueue.registerDetection(of: queueUsed)
    }
    
    @discardableResult
    /// Perform task that will executed after previous task
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    ///   - execute: Task to execute
    /// - Returns: Promise of next result
    open func then<NextResult>(on dispatcher: DispatchQueue, do execute: @escaping (Result) throws -> NextResult) -> Promise<NextResult> {
        let promise: Promise<NextResult> = .init(currentQueue: dispatcher)
        defer {
            registerChild(promise)
            registerWorker { input in
                syncIfPossible(on: dispatcher) {
                    do {
                        let result = try execute(input)
                        promise.currentValue = result
                    } catch {
                        promise.drop(becauseOf: error)
                    }
                }
            }
        }
        return promise
    }
    
    /// Perform task that will executed after previous task and return a promise
    /// - Parameters:
    ///   - createNewPromise: Task that will execute and producing new promise
    ///   - dispatcher: Dispatcher where the task will executed
    /// - Returns: new promise
    public func thenContinue<NextResult>(on dispatcher: DispatchQueue, with createNewPromise: @escaping (Result) throws -> Promise<NextResult>) -> Promise<NextResult> {
        let promise: NestedPromise<NextResult> = .init(currentQueue: dispatcher)
        defer {
            registerChild(promise)
            registerWorker { input in
                syncIfPossible(on: dispatcher) {
                    do {
                        let newPromise = try createNewPromise(input)
                        promise.nested = newPromise
                    } catch {
                        promise.drop(becauseOf: error)
                    }
                }
            }
        }
        return promise
    }
    
    @discardableResult
    /// Handle error if occurs in previous task
    /// - Parameter handling: Error handler
    /// - Returns: current Promise
    open func handle(_ handling: @escaping (Error) -> Void) -> Promise<Result> {
        registerHandler(handling)
        return self
    }
    
    @discardableResult
    /// Perform task after all previous task is finished
    /// - Parameters:
    ///   - dispatcher: Dispatcher where the task will executed
    /// - Parameter execute: Task to execute
    /// - Returns: New void promise
    public func finally(on dispatcher: DispatchQueue, do execute: @escaping PromiseConsumer<Result>) -> VoidPromise {
        then(on: dispatcher) { result in
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
    
    func getResultAfterGroupWait(_ timeoutResult: DispatchTimeoutResult, _ timeout: TimeInterval) throws -> Result {
        if let result = currentValue {
            return result
        } else if let error = error {
            throw error
        }
        switch timeoutResult {
        case .success:
            throw ErgoError(
                errorDescription: "Ergo Error: Invalid result",
                failureReason: "Waiting but still get no result or error"
            )
        case .timedOut:
            throw ErgoError(
                errorDescription: "Ergo Error: Timeout",
                failureReason: "waiting for \(timeout) second but still get no result or error"
            )
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func register(continuation: CheckedContinuation<Result, Error>) {
        if let result = currentValue {
            continuation.resume(returning: result)
            return
        } else if let error = error {
            continuation.resume(throwing: error)
            return
        }
        locked {
            abstractContinuations.append(continuation)
        }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func notifyContinuation(with result: Swift.Result<Result, Error>) {
        var dequeued: [CheckedContinuation<Result, Error>] = []
        locked {
            dequeued = abstractContinuations.compactMap { $0 as? CheckedContinuation<Result, Error> }
            abstractContinuations = []
        }
        dequeued.forEach { $0.resume(with: result) }
    }
    
    func registerWorker(_ worker: @escaping (Result) -> Void) {
        guard let result: Result = self.currentValue else {
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
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            notifyContinuation(with: .failure(error))
        }
    }
    
    func notifyWorker(with result: Result) {
        dequeueWorkers().forEach { worker in
            worker(result)
        }
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            notifyContinuation(with: .success(result))
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
