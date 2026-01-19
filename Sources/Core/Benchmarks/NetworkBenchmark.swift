//
//  NetworkBenchmark.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

@preconcurrency
struct NetworkBenchmark: Benchmark {
    let name: String = "Network: Download"
    let category: BenchmarkCategory = .disk // or create .network

    let url: URL

    init(url: URL) {
        self.url = url
    }

    func run(context: BenchmarkContext) async throws -> BenchmarkResult {
        let started = Metrics.now()

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
        request.httpMethod = "GET"

        // latency to first byte is tricky; here we measure total time + bytes
        let startNs = DispatchTime.now().uptimeNanoseconds
        let (data, response) = try await URLSession.shared.data(for: request)
        let endNs = DispatchTime.now().uptimeNanoseconds

        let elapsedMs = Double(endNs - startNs) / 1_000_000.0
        let bytes = data.count
        let mb = Double(bytes) / (1024.0 * 1024.0)
        let seconds = max(0.000_001, elapsedMs / 1000.0)
        let mbps = mb / seconds

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let ended = Metrics.now()

        return BenchmarkResult(
            name: name,
            category: category,
            startedAt: started,
            endedAt: ended,
            metrics: [
                .init(key: "HTTP", value: Double(statusCode), unit: .bytes),
                .init(key: "Elapsed", value: elapsedMs, unit: .ms),
                .init(key: "Bytes", value: Double(bytes), unit: .bytes),
                .init(key: "MB", value: mb, unit: .mb),
                .init(key: "Throughput", value: mbps, unit: .mbPerSec)
            ],
            notes: "Higher MB/s is better. URL=\(url.host ?? "")"
        )
    }
}

