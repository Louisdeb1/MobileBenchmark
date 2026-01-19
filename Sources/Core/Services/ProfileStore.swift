//
//  ProfileStore.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

final class ProfileStore {
    nonisolated(unsafe) static let shared = ProfileStore()
    private init() {}

    private let key = "benchmark.profile.selected"

    func saveSelectedProfileID(_ id: BenchmarkProfileID) {
        UserDefaults.standard.set(id.rawValue, forKey: key)
    }

    func loadSelectedProfileID() -> BenchmarkProfileID {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let id = BenchmarkProfileID(rawValue: raw) else {
            return .ciBaseline
        }
        return id
    }
}
