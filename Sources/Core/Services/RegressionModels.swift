//
//  RegressionModels.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

struct Baseline: Codable {
    let createdAt: Date
    let device: [String: String]
    let results: [BenchmarkResult]
}

struct RegressionRule: Codable, Hashable {
    /// Metric key to compare (e.g., "Elapsed", "Throughput", "Avg FPS")
    let metricKey: String
    /// Allowed relative change. Example: 0.05 means 5%
    let maxRegressionRatio: Double
    /// true = higher is better (e.g. MB/s), false = lower is better (e.g. ms)
    let higherIsBetter: Bool
}

struct RegressionCheck: Identifiable {
    let id = UUID()
    let benchmarkName: String
    let metricKey: String
    let baselineValue: Double
    let currentValue: Double
    let deltaRatio: Double
    let passed: Bool
}
