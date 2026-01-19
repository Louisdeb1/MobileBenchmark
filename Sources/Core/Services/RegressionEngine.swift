//
//  RegressionEngine.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

enum RegressionEngine {
    static func compare(baseline: Baseline,
                        current: [BenchmarkResult],
                        rules: [RegressionRule]) -> [RegressionCheck] {

        // Index results by name for matching
        let baseByName = Dictionary(uniqueKeysWithValues: baseline.results.map { ($0.name, $0) })
        let currByName = Dictionary(uniqueKeysWithValues: current.map { ($0.name, $0) })

        var checks: [RegressionCheck] = []

        for rule in rules {
            // Find benchmark that contains metricKey in both baseline/current
            for (name, bRes) in baseByName {
                guard let cRes = currByName[name] else { continue }

                guard let bMetric = bRes.metrics.first(where: { $0.key == rule.metricKey }),
                      let cMetric = cRes.metrics.first(where: { $0.key == rule.metricKey }) else { continue }

                let b = bMetric.value
                let c = cMetric.value
                if b == 0 { continue }

                // deltaRatio: positive means improvement for "higherIsBetter"
                let rawRatio = (c - b) / abs(b)
                let deltaRatio = rule.higherIsBetter ? rawRatio : -rawRatio

                // regression if deltaRatio < -maxRegressionRatio
                let passed = deltaRatio >= -rule.maxRegressionRatio

                checks.append(
                    RegressionCheck(
                        benchmarkName: name,
                        metricKey: rule.metricKey,
                        baselineValue: b,
                        currentValue: c,
                        deltaRatio: deltaRatio,
                        passed: passed
                    )
                )
            }
        }

        return checks
    }
}
