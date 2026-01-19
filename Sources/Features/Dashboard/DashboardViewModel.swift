//
//  DashboardViewModel.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation

@MainActor
final public class DashboardViewModel: ObservableObject {
    @Published var status: BenchmarkStatus = .idle
    @Published var results: [BenchmarkResult] = []
    
    @Published var exportItems: [Any] = []
    @Published var showShareSheet: Bool = false
    
    @Published var lastFpsSamplesMs: [Double] = []

    @Published var regressionChecks: [RegressionCheck] = []
    @Published var showRegression: Bool = false
    
    @Published var selectedProfile: BenchmarkProfile = .preset(ProfileStore.shared.loadSelectedProfileID())
    @Published var customProfile: BenchmarkProfile = .preset(.custom)
    @Published var showProfiles: Bool = false
    
    @Published var ciRuns: Int = 5
    @Published var preflightWarnings: [String] = []
    @Published var preflightSuggestions: [String] = []
    @Published var isCIRunning: Bool = false
    
    // Tunables
    var iterations: Int {
        get { selectedProfile.iterations }
        set { updateSelectedProfile { $0.iterations = newValue } }
    }

    var payloadMB: Int {
        get { selectedProfile.payloadMB }
        set { updateSelectedProfile { $0.payloadMB = newValue } }
    }
    
    

    private var benchmarks: [Benchmark] = [
        CpuBenchmark(),
        MemoryBenchmark(),
        DiskBenchmark(),
        FpsBenchmark(seconds: 8, intensity: 6),
        GpuBenchmark(elementCount: 8_388_608, passes: 30),
        SustainedCpuThermalBenchmark(seconds: 20),
        NetworkBenchmark(url: URL(string: "http://ipv4.download.thinkbroadband.com/100MB.zip"/* "https://speed.hetzner.de/100MB.bin"*/)!) // replace
    ]
    
    // Default rules (tune as needed)
    private let regressionRules: [RegressionRule] = [
        .init(metricKey: "Elapsed", maxRegressionRatio: 0.08, higherIsBetter: false),          // <= 8% slower ok
        .init(metricKey: "Throughput", maxRegressionRatio: 0.08, higherIsBetter: true),       // <= 8% lower ok
        .init(metricKey: "Write Throughput", maxRegressionRatio: 0.10, higherIsBetter: true), // <= 10% lower ok
        .init(metricKey: "Read Throughput", maxRegressionRatio: 0.10, higherIsBetter: true),
        .init(metricKey: "Avg FPS", maxRegressionRatio: 0.05, higherIsBetter: true),          // <= 5% lower ok
        .init(metricKey: "P95 Frame", maxRegressionRatio: 0.08, higherIsBetter: false)        // <= 8% higher ok
    ]

    func run() async {
        guard status != .running else { return }

        status = .running
        results.removeAll()

        let ctx = BenchmarkContext(
            iterations: iterations,
            payloadSizeBytes: payloadMB * 1024 * 1024,
            tempDirectory: FileManager.default.temporaryDirectory
        )
        
        // Build runner and suite locally to avoid sending main-actor isolated state across actors
        let localRunner = BenchmarkRunner()
        nonisolated(unsafe) let suite = self.makeBenchmarks(from: self.selectedProfile)
        let newResults = await localRunner.runAll(benchmarks: suite, context: ctx)
        
        self.results = newResults
        self.status = .finished
        
        self.lastFpsSamplesMs = FpsSampleStore.shared.get()
    }
    
    func export() {
        guard !results.isEmpty else { return }
        do {
            let dir = FileManager.default.temporaryDirectory
            let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let jsonURL = dir.appendingPathComponent("benchmark-\(stamp).json")
            let csvURL = dir.appendingPathComponent("benchmark-\(stamp).csv")
            
            try ExportService.exportJSON(results: results, to: jsonURL)
            try ExportService.exportCSV(results: results, to: csvURL)
            
            exportItems = [jsonURL, csvURL]
            showShareSheet = true
        } catch {
            print("Export failed: \(error.localizedDescription)")
        }
    }

    func cancel() {
        status = .idle
    }
    
    @MainActor func saveBaseline() {
        guard !results.isEmpty else { return }
        do {
            let baseline = Baseline(
                createdAt: Date(),
                device: DeviceInfo.summaryDictionary(),
                results: results
            )
            try BaselineStore.shared.save(baseline: baseline)
        } catch {
            print("Baseline save failed: \(error.localizedDescription)")
        }
    }

    func compareToBaseline() {
        guard !results.isEmpty else { return }
        do {
            let base = try BaselineStore.shared.loadBaseline()
            let checks = RegressionEngine.compare(baseline: base, current: results, rules: regressionRules)
            regressionChecks = checks
            showRegression = true
        } catch {
            print("Load baseline failed: \(error.localizedDescription)")
        }
    }
    
    private func updateSelectedProfile(_ mutate: (inout BenchmarkProfile) -> Void) {
        var p = selectedProfile
        mutate(&p)

        // If user tweaks a preset, we switch to custom
        if p.id != .custom {
            customProfile = p.with(id: .custom)
            selectedProfile = customProfile
            ProfileStore.shared.saveSelectedProfileID(.custom)
        } else {
            customProfile = p
            selectedProfile = p
            ProfileStore.shared.saveSelectedProfileID(.custom)
        }
    }

    private func makeBenchmarks(from profile: BenchmarkProfile) -> [Benchmark] {
        let url = URL(string: profile.networkURLString) ?? URL(string: "http://ipv4.download.thinkbroadband.com/100MB.zip")!

        return [
            CpuBenchmark(),
            MemoryBenchmark(),
            DiskBenchmark(),
            FpsBenchmark(seconds: profile.fpsSeconds, intensity: profile.fpsIntensity),
            GpuBenchmark(elementCount: profile.gpuElementCount, passes: profile.gpuPasses),
            SustainedCpuThermalBenchmark(seconds: profile.sustainedSeconds),
            NetworkBenchmark(url: url)
        ]
    }

    func applyProfile(_ profileID: BenchmarkProfileID) {
        let p: BenchmarkProfile
        if profileID == .custom {
            // Use saved custom if available in memory; else preset
            p = customProfile
        } else {
            p = BenchmarkProfile.preset(profileID)
        }
        selectedProfile = p
        ProfileStore.shared.saveSelectedProfileID(p.id)
    }

    func updateCustom(_ mutate: (inout BenchmarkProfile) -> Void) {
        var p = selectedProfile
        if p.id != .custom { p = p.with(id: .custom) }
        mutate(&p)
        customProfile = p
        selectedProfile = p
        ProfileStore.shared.saveSelectedProfileID(.custom)
    }
    
    func ciRun() {
        guard status != .running else { return }

        status = .running
        isCIRunning = true
        results.removeAll()
        regressionChecks.removeAll()
        preflightWarnings.removeAll()
        preflightSuggestions.removeAll()

        Task {
            // Preflight checks
            let report = await PreflightService.evaluateNetwork()
            await MainActor.run {
                self.preflightWarnings = report.warnings
                self.preflightSuggestions = report.suggestions
            }

            let runs = max(3, min(9, ciRuns)) // keep sane bounds
            let ctx = BenchmarkContext(
                iterations: selectedProfile.iterations,
                payloadSizeBytes: selectedProfile.payloadMB * 1024 * 1024,
                tempDirectory: FileManager.default.temporaryDirectory
            )

            let localRunner = BenchmarkRunner()
            var resultsByRun: [[BenchmarkResult]] = []

            for i in 1...runs {
                if self.status != .running { break }
                
                nonisolated(unsafe) let suite = self.makeBenchmarks(from: self.selectedProfile)
                let one = await localRunner.runAll(benchmarks: suite, context: ctx)

                resultsByRun.append(one)

                // Small cool-down / scheduling gap helps repeatability
                try? await Task.sleep(nanoseconds: 250_000_000) // 250ms
            }

            let aggregated = ResultsAggregator.medianAggregate(resultsByRun: resultsByRun)

            await MainActor.run {
                self.results = aggregated
                self.lastFpsSamplesMs = FpsSampleStore.shared.get()
            }

            if BaselineStore.shared.existsBaseline() {
                do {
                    let base = try BaselineStore.shared.loadBaseline()
                    let checks = RegressionEngine.compare(baseline: base, current: aggregated, rules: self.regressionRules)
                    await MainActor.run {
                        self.regressionChecks = checks
                        self.showRegression = true
                    }
                } catch {
                    print("CI: Load baseline failed: \(error.localizedDescription)")
                }
            } else {
                // Save baseline automatically
                var deviceSummary: [String: String] = [:]
                await MainActor.run {
                    deviceSummary = DeviceInfo.summaryDictionary()
                }
                do {
                    let baseline = Baseline(
                        createdAt: Date(),
                        device: deviceSummary,
                        results: aggregated
                    )
                    try BaselineStore.shared.save(baseline: baseline)
                } catch {
                    print("CI: Save baseline failed: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                self.status = .finished
                self.isCIRunning = false
            }
        }
    }

}
