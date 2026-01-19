//
//  ExportService.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

enum ExportService {
    static func exportJSON(results: [BenchmarkResult], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(results)
        try data.write(to: url, options: .atomic)
    }

    static func exportCSV(results: [BenchmarkResult], to url: URL) throws {
        // Flatten: one row per metric
        var lines: [String] = []
        lines.append("result_id,name,category,started_at,ended_at,duration_ms,metric_key,metric_value,metric_unit,notes")

        let iso = ISO8601DateFormatter()
        for r in results {
            for m in r.metrics {
                let row = [
                    r.id.uuidString.csvEscaped,
                    r.name.csvEscaped,
                    r.category.rawValue.csvEscaped,
                    iso.string(from: r.startedAt).csvEscaped,
                    iso.string(from: r.endedAt).csvEscaped,
                    String(format: "%.2f", r.durationMs).csvEscaped,
                    m.key.csvEscaped,
                    String(format: "%.6f", m.value).csvEscaped,
                    m.unit.rawValue.csvEscaped,
                    (r.notes ?? "").csvEscaped
                ].joined(separator: ",")
                lines.append(row)
            }
        }

        let csv = lines.joined(separator: "\n")
        try csv.data(using: .utf8)!.write(to: url, options: .atomic)
    }
}

private extension String {
    var csvEscaped: String {
        // Escape quotes and wrap in quotes if needed
        let needsQuotes = contains(",") || contains("\"") || contains("\n")
        var s = replacingOccurrences(of: "\"", with: "\"\"")
        if needsQuotes { s = "\"\(s)\"" }
        return s
    }
}

