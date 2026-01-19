//
//  Benchmark.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

struct BenchmarkContext {
    let iterations: Int
    let payloadSizeBytes: Int
    let tempDirectory: URL
}

protocol Benchmark {
    var name: String { get }
    var category: BenchmarkCategory { get }
    func run(context: BenchmarkContext) async throws -> BenchmarkResult
}

