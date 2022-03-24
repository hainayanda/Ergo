//
//  Task+Extensions.swift
//  Ergo
//
//  Created by Nayanda Haberty on 24/03/22.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Task {
    /// Convert Task to promise
    /// - Returns: Promise from task
    func toPromise() -> Promise<Success> {
        let task = self
        return asyncAwaitPromise {
            try await task.value
        }
    }
}
