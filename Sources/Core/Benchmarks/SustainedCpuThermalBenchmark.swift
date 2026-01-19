//
//  SustainedCpuThermalBenchmark.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

@preconcurrency
struct SustainedCpuThermalBenchmark: Benchmark {
    let name: String = "CPU: Sustained + Thermal"
    let category: BenchmarkCategory = .cpu

    let seconds: Double

    init(seconds: Double = 20) {
        self.seconds = seconds
    }

    func run(context: BenchmarkContext) async throws -> BenchmarkResult {
        let started = Metrics.now()

        let endTime = Date().addingTimeInterval(seconds)
        var samples: [ProcessInfo.ThermalState] = []
        var loops: Int = 0
        var checksum: Double = 0

        while Date() < endTime {
            // Work chunk (~a few ms)
            for i in 1...50_000 {
                let x = Double(i + loops) * 0.000001
                checksum += sin(x) * cos(x) + sqrt(x + 1.0)
            }
            loops += 1
            samples.append(ProcessInfo.processInfo.thermalState)

            // Yield occasionally to keep UI responsive
            if loops % 10 == 0 { await Task.yield() }
        }

        let ended = Metrics.now()

        func thermalScore(_ s: ProcessInfo.ThermalState) -> Int {
            // nominal=0, fair=1, serious=2, critical=3
            switch s {
            case .nominal: return 0
            case .fair: return 1
            case .serious: return 2
            case .critical: return 3
            @unknown default: return 0
            }
        }

        let avgThermal = samples.isEmpty ? 0.0 : Double(samples.map(thermalScore).reduce(0, +)) / Double(samples.count)
        let maxThermal = samples.map(thermalScore).max() ?? 0

        let durationMs = ended.timeIntervalSince(started) * 1000
        let opsPerSec = Double(loops) / max(0.000_001, durationMs / 1000.0)

        return BenchmarkResult(
            name: name,
            category: category,
            startedAt: started,
            endedAt: ended,
            metrics: [
                .init(key: "Duration", value: durationMs, unit: .ms),
                .init(key: "Work Loops/sec", value: opsPerSec, unit: .opsPerSec),
                .init(key: "Thermal Avg", value: avgThermal, unit: .bytes),
                .init(key: "Thermal Max", value: Double(maxThermal), unit: .bytes),
                .init(key: "Checksum", value: checksum.truncatingRemainder(dividingBy: 1_000_000), unit: .bytes)
            ],
            notes: "Thermal: 0=nominal,1=fair,2=serious,3=critical. Watch for throttling."
        )
    }
}

