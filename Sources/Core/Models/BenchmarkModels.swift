//
//  BenchmarkModels.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

public enum BenchmarkCategory: String, Codable, CaseIterable {
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

public struct BenchmarkResult: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let category: BenchmarkCategory
    public let startedAt: Date
    public let endedAt: Date
    public let durationMs: Double
    public let metrics: [MetricValue]
    public let notes: String?

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

public enum MetricUnit: String, Codable {
    case ms
    case opsPerSec
    case mb
    case mbPerSec
    case percent
    case bytes
}

public  struct MetricValue: Identifiable, Codable {
    public let id: UUID
    public let key: String
    public let value: Double
    public let unit: MetricUnit

    init(id: UUID = UUID(), key: String, value: Double, unit: MetricUnit) {
        self.id = id
        self.key = key
        self.value = value
        self.unit = unit
    }
}

