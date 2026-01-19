//
//  FpsChartsView.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import SwiftUI
import Charts

struct FpsChartsView: View {
    let samplesMs: [Double]

    struct Bucket: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let lower: Double
        let upper: Double
    }

    var body: some View {
        List {
            Section("FPS Histogram (Frame Time ms)") {
                if samplesMs.count < 10 {
                    Text("Not enough samples. Run the FPS benchmark.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(buckets) { b in
                        BarMark(
                            x: .value("Bucket", b.label),
                            y: .value("Count", b.count)
                        )
                    }
                    .frame(height: 220)
                }
            }

            Section("Summary") {
                let p50 = percentile(samplesMs, p: 0.50)
                let p95 = percentile(samplesMs, p: 0.95)
                let avg = samplesMs.reduce(0, +) / Double(samplesMs.count)
                let fpsAvg = avg > 0 ? 1000.0 / avg : 0

                HStack { Text("Avg FPS"); Spacer(); Text(String(format: "%.1f", fpsAvg)).foregroundStyle(.secondary) }
                HStack { Text("P50 ms"); Spacer(); Text(String(format: "%.2f", p50)).foregroundStyle(.secondary) }
                HStack { Text("P95 ms"); Spacer(); Text(String(format: "%.2f", p95)).foregroundStyle(.secondary) }
                HStack { Text("Samples"); Spacer(); Text("\(samplesMs.count)").foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("FPS Charts")
    }

    private var buckets: [Bucket] {
        // Buckets: <=16.7, 16.7-33.3, 33.3-50, 50-100, >100
        let ranges: [(String, Double, Double)] = [
            ("<=16.7", 0, 16.7),
            ("16.7-33.3", 16.7, 33.3),
            ("33.3-50", 33.3, 50),
            ("50-100", 50, 100),
            (">100", 100, Double.greatestFiniteMagnitude)
        ]

        return ranges.map { (label, lo, hi) in
            let c = samplesMs.filter { $0 > lo && $0 <= hi }.count
            return Bucket(label: label, count: c, lower: lo, upper: hi)
        }
    }

    private func percentile(_ values: [Double], p: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let s = values.sorted()
        let idx = max(0, min(s.count - 1, Int((Double(s.count - 1) * p).rounded())))
        return s[idx]
    }
}

