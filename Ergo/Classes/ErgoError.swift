//
//  ErgoError.swift
//  Ergo
//
//  Created by Nayanda Haberty on 01/07/21.
//

import Foundation

public struct ErgoError: LocalizedError {
    
    /// Description of error
    public let errorDescription: String?
    
    /// Reason of failure
    public let failureReason: String?
    
    init(errorDescription: String, failureReason: String? = nil) {
        self.errorDescription = errorDescription
        self.failureReason = failureReason
    }
}
