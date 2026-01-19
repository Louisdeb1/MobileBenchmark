//
//  RegressionView.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import SwiftUI

struct RegressionView: View {
    let checks: [RegressionCheck]

    var body: some View {
        List {
            Section("Overall") {
                let passed = checks.allSatisfy { $0.passed }
                HStack {
                    Text("Status")
                    Spacer()
                    Text(passed ? "PASS" : "FAIL")
                        .fontWeight(.semibold)
                        .foregroundStyle(passed ? .green : .red)
                }
                Text("Rules applied: \(checks.count)")
                    .foregroundStyle(.secondary)
            }

            Section("Details") {
                if checks.isEmpty {
                    Text("No checks. Ensure baseline exists and rules match metric keys.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(checks, id: \.metricKey) { (c: RegressionCheck) in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(c.benchmarkName).font(.headline)
                                Spacer()
                                Text(c.passed ? "PASS" : "FAIL")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.thinMaterial)
                                    .clipShape(Capsule())
                            }
                            Text("Metric: \(c.metricKey)")
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("Baseline")
                                Spacer()
                                Text(String(format: "%.4f", c.baselineValue))
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("Current")
                                Spacer()
                                Text(String(format: "%.4f", c.currentValue))
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("Delta")
                                Spacer()
                                Text(String(format: "%+.2f%%", c.deltaRatio * 100))
                                    .foregroundStyle(c.passed ? .secondary : .tertiary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Regression")
    }
}

