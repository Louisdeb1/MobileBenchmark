//
//  CpuBenchmark.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

@preconcurrency
struct CpuBenchmark: Benchmark {
    let name: String = "CPU: Math Loop"
    let category: BenchmarkCategory = .cpu

    func run(context: BenchmarkContext) async throws -> BenchmarkResult {
        let started = Metrics.now()

        // Simple deterministic workload
        var accumulator: Double = 0
        let iterations = max(1, context.iterations * 2_000_000)

        let elapsedMs = Metrics.measureMs {
            for i in 1...iterations {
                // a bit of trig + sqrt to keep CPU busy
                let x = Double(i) * 0.000001
                accumulator += sin(x) * cos(x) + sqrt(x + 1.0)
            }
        }

        // Prevent optimizer from removing work
        let checksum = accumulator

        let ended = Metrics.now()

        let seconds = max(0.000_001, elapsedMs / 1000.0)
        let opsPerSec = Double(iterations) / seconds

        return BenchmarkResult(
            name: name,
            category: category,
            startedAt: started,
            endedAt: ended,
            metrics: [
                .init(key: "Elapsed", value: elapsedMs, unit: .ms),
                .init(key: "Throughput", value: opsPerSec, unit: .opsPerSec),
                .init(key: "Checksum", value: checksum.truncatingRemainder(dividingBy: 1_000_000), unit: .bytes)
            ],
            notes: "Higher ops/sec is better."
        )
    }
}

