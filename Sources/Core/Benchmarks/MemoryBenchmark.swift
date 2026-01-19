//
//  MemoryBenchmark.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

@preconcurrency
struct MemoryBenchmark: Benchmark {
    let name: String = "Memory: Allocate & Touch"
    let category: BenchmarkCategory = .memory

    func run(context: BenchmarkContext) async throws -> BenchmarkResult {
        let started = Metrics.now()
        let beforeMB = Metrics.residentMemoryMB()

        let size = max(1_048_576, context.payloadSizeBytes) // at least 1MB
        let elapsedMs = Metrics.measureMs {
            // Allocate and touch every page-ish to force commit
            var buffer = [UInt8](repeating: 0, count: size)
            let value = 4096
            var sum: UInt64 = 0
            for i in stride(from: 0, to: buffer.count, by: value) {
                buffer[i] = UInt8((i / value) % 255)
                sum &+= UInt64(buffer[i])
            }
            // Keep buffer alive
            if sum == 42 { print("impossible") }
        }

        let afterMB = Metrics.residentMemoryMB()
        let ended = Metrics.now()

        let delta = (beforeMB >= 0 && afterMB >= 0) ? (afterMB - beforeMB) : -1

        return BenchmarkResult(
            name: name,
            category: category,
            startedAt: started,
            endedAt: ended,
            metrics: [
                .init(key: "Elapsed", value: elapsedMs, unit: .ms),
                .init(key: "Resident Before", value: beforeMB, unit: .mb),
                .init(key: "Resident After", value: afterMB, unit: .mb),
                .init(key: "Delta", value: delta, unit: .mb)
            ],
            notes: "Lower elapsed is better. Delta is approximate; iOS memory accounting varies."
        )
    }
}

