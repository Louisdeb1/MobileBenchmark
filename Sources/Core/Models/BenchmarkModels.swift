//
//  BenchmarkModels.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

enum BenchmarkCategory: String, Codable, CaseIterable {
    case cpu = "CPU"
    case memory = "Memory"
    case disk = "Disk"
}

enum BenchmarkStatus: String, Codable {
    case idle
    case running
    case finished
    case failed
}

struct BenchmarkResult: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: BenchmarkCategory
    let startedAt: Date
    let endedAt: Date
    let durationMs: Double
    let metrics: [MetricValue]
    let notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        category: BenchmarkCategory,
        startedAt: Date,
        endedAt: Date,
        metrics: [MetricValue],
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationMs = max(0, endedAt.timeIntervalSince(startedAt) * 1000)
        self.metrics = metrics
        self.notes = notes
    }
}

enum MetricUnit: String, Codable {
    case ms
    case opsPerSec
    case mb
    case mbPerSec
    case percent
    case bytes
}

struct MetricValue: Identifiable, Codable {
    let id: UUID
    let key: String
    let value: Double
    let unit: MetricUnit

    init(id: UUID = UUID(), key: String, value: Double, unit: MetricUnit) {
        self.id = id
        self.key = key
        self.value = value
        self.unit = unit
    }
}

