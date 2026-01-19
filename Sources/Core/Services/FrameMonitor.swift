//
//  FrameMonitor.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation
import QuartzCore
import UIKit

@preconcurrency
final class FrameMonitor {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private(set) var frameTimesMs: [Double] = []

    func start() {
        frameTimesMs.removeAll()
        lastTimestamp = 0
        displayLink?.invalidate()

        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = 0
    }

    @objc private func tick(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }
        let dt = (link.timestamp - lastTimestamp) * 1000.0
        lastTimestamp = link.timestamp
        frameTimesMs.append(dt)
    }

    struct Summary {
        let fpsAvg: Double
        let p50Ms: Double
        let p95Ms: Double
        let jankCount: Int
        let samples: Int
    }

    func summarize(targetFrameMs: Double = 16.67, jankThresholdMultiplier: Double = 2.0) -> Summary {
        let samples = frameTimesMs.count
        guard samples > 10 else {
            return Summary(fpsAvg: 0, p50Ms: 0, p95Ms: 0, jankCount: 0, samples: samples)
        }

        let sorted = frameTimesMs.sorted()
        func percentile(_ p: Double) -> Double {
            let idx = max(0, min(sorted.count - 1, Int((Double(sorted.count - 1) * p).rounded())))
            return sorted[idx]
        }

        let avgMs = frameTimesMs.reduce(0, +) / Double(samples)
        let fpsAvg = avgMs > 0 ? 1000.0 / avgMs : 0
        let p50 = percentile(0.50)
        let p95 = percentile(0.95)
        let jankThreshold = targetFrameMs * jankThresholdMultiplier
        let jank = frameTimesMs.filter { $0 > jankThreshold }.count

        return Summary(fpsAvg: fpsAvg, p50Ms: p50, p95Ms: p95, jankCount: jank, samples: samples)
    }
}

