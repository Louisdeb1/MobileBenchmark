//
//  FpsBenchmark.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation
import SwiftUI
import UIKit

@preconcurrency
struct FpsBenchmark: Benchmark {
    let name: String = "UI: FPS & Jank"
    let category: BenchmarkCategory = .cpu // you can create a .ui category if you want

    let seconds: Double
    let intensity: Int

    init(seconds: Double = 8.0, intensity: Int = 6) {
        self.seconds = seconds
        self.intensity = max(1, min(10, intensity))
    }

    func run(context: BenchmarkContext) async throws -> BenchmarkResult {
        let started = Metrics.now()

        // Present a temporary full-screen controller hosting the workload SwiftUI view.
        let monitor = FrameMonitor()

        try await MainActor.run {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first,
                  let root = window.rootViewController else {
                throw NSError(domain: "FpsBenchmark", code: 1, userInfo: [NSLocalizedDescriptionKey: "No root VC"])
            }

            let host = UIHostingController(rootView: FpsWorkloadView(intensity: intensity))
            host.modalPresentationStyle = .fullScreen
            root.present(host, animated: false)

            monitor.start()

            // Stop after duration and dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                monitor.stop()
                host.dismiss(animated: false)
            }
        }

        // Wait for the duration to pass (+ small buffer)
        try await Task.sleep(nanoseconds: UInt64((seconds + 0.25) * 1_000_000_000))

        let summary = monitor.summarize()
        let ended = Metrics.now()

        let rawSamples = monitor.frameTimesMs
        FpsSampleStore.shared.set(samples: rawSamples)
        
        return BenchmarkResult(
            name: name,
            category: category,
            startedAt: started,
            endedAt: ended,
            metrics: [
                .init(key: "Avg FPS", value: summary.fpsAvg, unit: .opsPerSec),
                .init(key: "P50 Frame", value: summary.p50Ms, unit: .ms),
                .init(key: "P95 Frame", value: summary.p95Ms, unit: .ms),
                .init(key: "Jank Frames", value: Double(summary.jankCount), unit: .bytes),
                .init(key: "Samples", value: Double(summary.samples), unit: .bytes)
            ],
            notes: "Lower P95 and fewer jank frames are better. Intensity=\(intensity), duration=\(seconds)s."
        )
    }
}

