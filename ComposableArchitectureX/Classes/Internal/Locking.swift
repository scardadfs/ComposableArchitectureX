//
//  Locking.swift
//  ComposableArchitectureX

import Foundation

extension NSRecursiveLock {
    @inlinable
    func sync(work: () -> Void) {
        lock()
        defer { self.unlock() }
        work()
    }
}
