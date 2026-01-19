//
//  BenchmarkProfile.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation


struct BenchmarkProfile: Codable, Equatable {
    var id: BenchmarkProfileID

    // General
    var iterations: Int
    var payloadMB: Int

    // FPS/Jank
    var fpsSeconds: Double
    var fpsIntensity: Int

    // GPU Metal
    var gpuElementCount: Int
    var gpuPasses: Int

    // Sustained thermal
    var sustainedSeconds: Double

    // Network
    var networkURLString: String

    static func preset(_ id: BenchmarkProfileID) -> BenchmarkProfile {
        switch id {
        case .gaming:
            return BenchmarkProfile(
                id: .gaming,
                iterations: 3,
                payloadMB: 96,
                fpsSeconds: 12,
                fpsIntensity: 8,
                gpuElementCount: 12_582_912, // ~48MB per buffer
                gpuPasses: 45,
                sustainedSeconds: 30,
                networkURLString: "http://ipv4.download.thinkbroadband.com/100MB.zip"
            )

        case .batteryFriendly:
            return BenchmarkProfile(
                id: .batteryFriendly,
                iterations: 1,
                payloadMB: 16,
                fpsSeconds: 6,
                fpsIntensity: 4,
                gpuElementCount: 4_194_304, // ~16MB per buffer
                gpuPasses: 12,
                sustainedSeconds: 12,
                networkURLString: "http://ipv4.download.thinkbroadband.com/100MB.zip"
            )

        case .ciBaseline:
            return BenchmarkProfile(
                id: .ciBaseline,
                iterations: 2,
                payloadMB: 32,
                fpsSeconds: 8,
                fpsIntensity: 6,
                gpuElementCount: 8_388_608, // ~32MB per buffer
                gpuPasses: 30,
                sustainedSeconds: 15,
                networkURLString: "http://ipv4.download.thinkbroadband.com/100MB.zip"
            )

        case .custom:
            // Start custom with CI-like defaults
            return preset(.ciBaseline).with(id: .custom)
        }
    }

    func with(id: BenchmarkProfileID) -> BenchmarkProfile {
        var copy = self
        copy.id = id
        return copy
    }
}
