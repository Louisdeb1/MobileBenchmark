//
//  MobileBenchmarkSuite.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/19/26.
//

import Foundation

public enum BenchmarkProfileID: String, Codable, CaseIterable, Identifiable {
    case gaming
    case batteryFriendly
    case ciBaseline
    case custom
    
    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .gaming: return "Gaming"
        case .batteryFriendly: return "Battery-friendly"
        case .ciBaseline: return "CI Baseline"
        case .custom: return "Custom"
        }
    }

    public var subtitle: String {
        switch self {
        case .gaming: return "Higher load: FPS + GPU heavier, larger payloads."
        case .batteryFriendly: return "Shorter tests with smaller payloads."
        case .ciBaseline: return "Repeatable settings for regression checks."
        case .custom: return "Your own tunable settings."
        }
    }
}

public struct MobileBenchmarkSuite {
    private let benchmarks: [any Benchmark]
    private let context: BenchmarkContext

    public static func `default`(profile: BenchmarkProfileID = .ciBaseline) -> MobileBenchmarkSuite {
        let p = profileDefaults(profile)
        let suite: [any Benchmark] = [
            CpuBenchmark(),
            MemoryBenchmark(),
            DiskBenchmark(),
            FpsBenchmark(seconds: p.fpsSeconds, intensity: p.fpsIntensity),
            GpuBenchmark(elementCount: p.gpuElementCount, passes: p.gpuPasses),
            SustainedCpuThermalBenchmark(seconds: p.sustainedSeconds),
            NetworkBenchmark(url: p.url)
        ]

        let ctx = BenchmarkContext(
            iterations: p.iterations,
            payloadSizeBytes: p.payloadMB * 1024 * 1024,
            tempDirectory: FileManager.default.temporaryDirectory
        )
        return MobileBenchmarkSuite(benchmarks: suite, context: ctx)
    }

    public func run() async -> [BenchmarkResult] {
        let runner = BenchmarkRunner()
        return await runner.runAll(benchmarks: benchmarks, context: context)
    }

    // MARK: - Defaults (keep lightweight)
    private static func profileDefaults(_ id: BenchmarkProfileID) -> Defaults {
        switch id {
        case .gaming:
            return Defaults(iterations: 3, payloadMB: 96, fpsSeconds: 12, fpsIntensity: 8,
                            gpuElementCount: 12_582_912, gpuPasses: 45, sustainedSeconds: 30,
                            url: URL(string: "https://speed.hetzner.de/100MB.bin")!)
        case .batteryFriendly:
            return Defaults(iterations: 1, payloadMB: 16, fpsSeconds: 6, fpsIntensity: 4,
                            gpuElementCount: 4_194_304, gpuPasses: 12, sustainedSeconds: 12,
                            url: URL(string: "https://speed.hetzner.de/10MB.bin")!)
        case .ciBaseline, .custom:
            return Defaults(iterations: 2, payloadMB: 32, fpsSeconds: 8, fpsIntensity: 6,
                            gpuElementCount: 8_388_608, gpuPasses: 30, sustainedSeconds: 15,
                            url: URL(string: "https://speed.hetzner.de/100MB.bin")!)
        }
    }

    private struct Defaults {
        let iterations: Int
        let payloadMB: Int
        let fpsSeconds: Double
        let fpsIntensity: Int
        let gpuElementCount: Int
        let gpuPasses: Int
        let sustainedSeconds: Double
        let url: URL
    }
}
