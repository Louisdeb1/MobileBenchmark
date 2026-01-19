//
//  PreflightService.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation
import Network

struct PreflightReport {
    let warnings: [String]
    let suggestions: [String]
}

enum PreflightService {
    static func evaluateNetwork(timeoutSeconds: Double = 1.0) async -> PreflightReport {
        var warnings: [String] = []
        var suggestions: [String] = []

        // Power / thermal
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            warnings.append("Low Power Mode is ON (results may be throttled).")
            suggestions.append("Turn off Low Power Mode for stable results.")
        }

        let t = ProcessInfo.processInfo.thermalState
        switch t {
        case .nominal:
            break
        case .fair:
            warnings.append("Thermal state: FAIR (minor throttling possible).")
            suggestions.append("Let the device cool down for more stable results.")
        case .serious:
            warnings.append("Thermal state: SERIOUS (throttling likely).")
            suggestions.append("Close apps and cool the device before running.")
        case .critical:
            warnings.append("Thermal state: CRITICAL (heavy throttling likely).")
            suggestions.append("Stop heavy usage, cool device, then re-run.")
        @unknown default:
            break
        }

        // Network path
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "preflight.nwpath")

        // Use an actor to serialize state mutations from concurrent callbacks
        actor PreflightState {
            private(set) var finished = false
            private(set) var warnings: [String]
            private(set) var suggestions: [String]

            init(warnings: [String], suggestions: [String]) {
                self.warnings = warnings
                self.suggestions = suggestions
            }

            func tryFinish() -> Bool {
                guard !finished else { return false }
                finished = true
                return true
            }

            func addWarning(_ text: String) {
                warnings.append(text)
            }

            func addSuggestion(_ text: String) {
                suggestions.append(text)
            }

            func report() -> PreflightReport {
                PreflightReport(warnings: warnings, suggestions: suggestions)
            }
        }

        let state = PreflightState(warnings: warnings, suggestions: suggestions)

        return await withCheckedContinuation { cont in
            monitor.pathUpdateHandler = { path in
                Task {
                    // Ensure only the first completion path proceeds
                    guard await state.tryFinish() else { return }

                    if path.status != .satisfied {
                        await state.addWarning("Network appears OFFLINE (network benchmark will fail or skew).")
                        await state.addSuggestion("Connect to stable Wi-Fi for repeatable throughput.")
                    } else {
                        if path.isExpensive {
                            await state.addWarning("Network is EXPENSIVE (likely Cellular) — throughput varies more.")
                            await state.addSuggestion("Prefer Wi-Fi for CI Baseline stability.")
                        }
                        if path.isConstrained {
                            await state.addWarning("Network is CONSTRAINED (Low Data Mode / constrained path).")
                            await state.addSuggestion("Disable Low Data Mode for consistent network tests.")
                        }
                        if path.usesInterfaceType(.cellular) {
                            await state.addWarning("Using Cellular network — results are less repeatable than Wi-Fi.")
                        }
                    }

                    monitor.cancel()
                    cont.resume(returning: await state.report())
                }
            }

            monitor.start(queue: queue)

            // Timeout fallback
            queue.asyncAfter(deadline: .now() + timeoutSeconds) {
                Task {
                    guard await state.tryFinish() else { return }
                    await state.addWarning("Network preflight timed out (continuing).")
                    monitor.cancel()
                    cont.resume(returning: await state.report())
                }
            }
        }
    }
}
