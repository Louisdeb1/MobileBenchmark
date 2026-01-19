//
//  DiskBenchmark.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

@preconcurrency
struct DiskBenchmark: Benchmark {
    let name: String = "Disk: Write/Read"
    let category: BenchmarkCategory = .disk

    func run(context: BenchmarkContext) async throws -> BenchmarkResult {
        let started = Metrics.now()

        let sizeBytes = max(2_000_000, context.payloadSizeBytes) // >= ~2MB
        let url = context.tempDirectory.appendingPathComponent("benchmark-\(UUID().uuidString).bin")

        let writeMs = Metrics.measureMs {
            try? FileIO.writeData(to: url, sizeBytes: sizeBytes)
        }

        let readMs = Metrics.measureMs {
            _ = try? FileIO.readAll(from: url)
        }

        try? FileManager.default.removeItem(at: url)

        let ended = Metrics.now()

        let sizeMB = Double(sizeBytes) / (1024.0 * 1024.0)
        let writeMBps = sizeMB / max(0.000_001, writeMs / 1000.0)
        let readMBps = sizeMB / max(0.000_001, readMs / 1000.0)

        return BenchmarkResult(
            name: name,
            category: category,
            startedAt: started,
            endedAt: ended,
            metrics: [
                .init(key: "Payload", value: sizeMB, unit: .mb),
                .init(key: "Write", value: writeMs, unit: .ms),
                .init(key: "Write Throughput", value: writeMBps, unit: .mbPerSec),
                .init(key: "Read", value: readMs, unit: .ms),
                .init(key: "Read Throughput", value: readMBps, unit: .mbPerSec)
            ],
            notes: "Higher MB/s is better. Uses app sandbox temp directory."
        )
    }
}

