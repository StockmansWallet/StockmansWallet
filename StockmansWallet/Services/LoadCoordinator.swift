//
//  LoadCoordinator.swift
//  StockmansWallet
//
//  Actor for coordinating async data loads to prevent race conditions
//  Performance: Automatically cancels previous loads when new ones start
//

import Foundation

/// Actor that coordinates async operations to prevent race conditions
/// Usage: Wrap async data loading operations to ensure only one runs at a time
/// Automatically cancels the previous operation when a new one starts
actor LoadCoordinator {
    // Debug: Store current running task so it can be cancelled
    private var currentTask: Task<Void, Error>?
    
    /// Execute an async operation, automatically cancelling any previous operation
    /// - Parameter operation: The async work to perform
    /// - Throws: Re-throws any errors from the operation (except CancellationError)
    func execute(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        // Cancel any existing task
        currentTask?.cancel()
        
        // Create and store new task
        let task = Task {
            try await operation()
        }
        currentTask = task
        
        // Wait for completion and propagate errors
        do {
            try await task.value
        } catch is CancellationError {
            // Expected when new load starts - don't propagate
            #if DEBUG
            print("🔄 LoadCoordinator: Previous operation cancelled (expected)")
            #endif
        } catch {
            // Propagate real errors
            throw error
        }
    }
    
    /// Cancel the currently running operation
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        #if DEBUG
        print("🔄 LoadCoordinator: Manually cancelled current operation")
        #endif
    }
}
