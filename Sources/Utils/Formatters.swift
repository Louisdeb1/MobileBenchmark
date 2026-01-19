//
//  Formatters.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

enum Formatters {
    static func metric(_ metric: MetricValue) -> String {
        switch metric.unit {
        case .ms:
            return String(format: "%.1f ms", metric.value)
        case .opsPerSec:
            return String(format: "%.0f ops/s", metric.value)
        case .mb:
            return String(format: "%.2f MB", metric.value)
        case .mbPerSec:
            return String(format: "%.2f MB/s", metric.value)
        case .percent:
            return String(format: "%.1f%%", metric.value)
        case .bytes:
            return String(format: "%.0f", metric.value)
        }
    }

    static func durationMs(_ value: Double) -> String {
        String(format: "%.1f ms", value)
    }
}

