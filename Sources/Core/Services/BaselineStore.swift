//
//  BaselineStore.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

final class BaselineStore {
    nonisolated(unsafe) static let shared = BaselineStore()
    private init() {}

    private let baseFileName = "baseline.json"
    private let currentFileName = "currentline.json"

    private var baseUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(baseFileName)
    }
    
    private var currentUrl: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(currentFileName)
    }

    func save(baseline: Baseline) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        let data = try enc.encode(baseline)
        try data.write(to: baseUrl, options: .atomic)
    }
    
    func save(current: Baseline) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        let data = try enc.encode(current)
        try data.write(to: currentUrl, options: .atomic)
    }


    func loadBaseline() throws -> Baseline {
        let data = try Data(contentsOf: baseUrl)
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(Baseline.self, from: data)
    }

    func existsBaseline() -> Bool {
        FileManager.default.fileExists(atPath: baseUrl.path)
    }
}
