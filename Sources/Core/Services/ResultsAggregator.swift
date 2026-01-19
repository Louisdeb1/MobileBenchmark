//
//  ResultsAggregator.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

struct AggregatedBenchmarkResult {
    let name: String
    let category: BenchmarkCategory
    let metrics: [MetricValue]   // aggregated values (median)
    let runs: Int
}

enum ResultsAggregator {
    /// Input: resultsByRun[runIndex] = [BenchmarkResult]
    /// Output: aggregated [BenchmarkResult] with medians per metric key
    static func medianAggregate(resultsByRun: [[BenchmarkResult]]) -> [BenchmarkResult] {
        guard let firstRun = resultsByRun.first, !firstRun.isEmpty else { return [] }

        // Group by benchmark name
        let all = resultsByRun.flatMap { $0 }
        let byBenchmark = Dictionary(grouping: all, by: { $0.name })

        var output: [BenchmarkResult] = []

        for (benchName, results) in byBenchmark {
            // Use most common category from runs (should be same)
            let category = results.first?.category ?? .cpu

            // Collect metric samples by key+unit
            struct Key: Hashable { let metricKey: String; let unit: MetricUnit }
            var samples: [Key: [Double]] = [:]

            for r in results {
                for m in r.metrics {
                    let k = Key(metricKey: m.key, unit: m.unit)
                    samples[k, default: []].append(m.value)
                }
            }

            let aggregatedMetrics: [MetricValue] = samples
                .map { (k, vals) in
                    MetricValue(key: k.metricKey, value: median(vals), unit: k.unit)
                }
                .sorted { $0.key < $1.key }

            // Duration: use median of durationMs too (handy)
            let dur = median(results.map { $0.durationMs })

            let started = results.map(\.startedAt).min() ?? Date()
            let ended = results.map(\.endedAt).max() ?? Date()

            let notes = "Aggregated median of \(results.count) runs."
            let agg = BenchmarkResult(
                name: benchName,
                category: category,
                startedAt: started,
                endedAt: ended,
                metrics: aggregatedMetrics,
                notes: notes
            )

            // Override durationMs via ended/started calculation is not exact; keep a metric too:
            let withDurationMetric = BenchmarkResult(
                name: agg.name,
                category: agg.category,
                startedAt: agg.startedAt,
                endedAt: agg.endedAt,
                metrics: ([MetricValue(key: "Median Duration", value: dur, unit: .ms)] + agg.metrics),
                notes: agg.notes
            )

            output.append(withDurationMetric)
        }

        // Stable ordering
        output.sort { $0.name < $1.name }
        return output
    }

    private static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let s = values.sorted()
        let mid = s.count / 2
        if s.count % 2 == 0 {
            return (s[mid - 1] + s[mid]) / 2.0
        } else {
            return s[mid]
        }
    }
}
