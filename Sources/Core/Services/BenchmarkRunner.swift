//
//  BenchmarkRunner.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

class BenchmarkRunner {
    func runAll( benchmarks: [Benchmark],
        context: BenchmarkContext) async -> [BenchmarkResult] {
        var results: [BenchmarkResult] = []

        for bm in benchmarks {
            do {
                let result = try await bm.run(context: context)
                results.append(result)
            } catch {
                // If one fails, keep going (or change behavior to stop)
                let started = Date()
                let ended = Date()
                let failed = BenchmarkResult(
                    name: bm.name,
                    category: bm.category,
                    startedAt: started,
                    endedAt: ended,
                    metrics: [],
                    notes: "Failed: \(error.localizedDescription)"
                )
                results.append(failed)
            }
        }

        return results
    }
}

