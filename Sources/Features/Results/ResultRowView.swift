//
//  ResultRowView.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import SwiftUI

struct ResultRowView: View {
    let result: BenchmarkResult

    var body: some View {
        NavigationLink {
            ResultDetailView(result: result)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(result.name)
                        .font(.headline)
                    Spacer()
                    Text(result.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                }

                Text("Duration: \(Formatters.durationMs(result.durationMs))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let top = result.metrics.first {
                    Text("\(top.key): \(Formatters.metric(top))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct ResultDetailView: View {
    let result: BenchmarkResult

    var body: some View {
        List {
            Section("Summary") {
                Text(result.name).font(.headline)
                Text("Category: \(result.category.rawValue)")
                Text("Duration: \(Formatters.durationMs(result.durationMs))")
                if let notes = result.notes {
                    Text(notes).foregroundStyle(.secondary)
                }
            }

            Section("Metrics") {
                if result.metrics.isEmpty {
                    Text("No metrics captured.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(result.metrics) { m in
                        HStack {
                            Text(m.key)
                            Spacer()
                            Text(Formatters.metric(m))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Result")
    }
}

