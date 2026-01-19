//
//  FpsSampleStore.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

final class FpsSampleStore {
    nonisolated(unsafe) static let shared = FpsSampleStore()
    private init() {}

    private let lock = NSLock()
    private var samples: [Double] = []

    func set(samples: [Double]) {
        lock.lock(); defer { lock.unlock() }
        self.samples = samples
    }

    func get() -> [Double] {
        lock.lock(); defer { lock.unlock() }
        return samples
    }
}

