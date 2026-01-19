//
//  FileIO.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

enum FileIO {
    static func writeData(to url: URL, sizeBytes: Int) throws {
        // Write in chunks to avoid huge allocations
        let chunkSize = 1_048_576 // 1 MB
        let totalChunks = max(1, sizeBytes / chunkSize)
        let remainder = sizeBytes % chunkSize

        // deterministic-ish data
        let chunk = Data((0..<chunkSize).map { _ in UInt8.random(in: 0...255) })

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        FileManager.default.createFile(atPath: url.path, contents: nil)

        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }

        for _ in 0..<totalChunks {
            try handle.write(contentsOf: chunk)
        }
        if remainder > 0 {
            let tail = Data((0..<remainder).map { _ in UInt8.random(in: 0...255) })
            try handle.write(contentsOf: tail)
        }
        try handle.synchronize()
    }

    static func readAll(from url: URL) throws -> Int {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        return data.count
    }
}

