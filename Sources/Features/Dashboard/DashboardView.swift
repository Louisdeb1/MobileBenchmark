//
//  DashboardView.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import SwiftUI

public struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()

    public init() { }
    
    public var body: some View {
        NavigationStack {
            List {
                Section("Configuration") {
                    Stepper("Iterations: \(vm.iterations)", value: $vm.iterations, in: 1...10)
                    Stepper("Payload: \(vm.payloadMB) MB", value: $vm.payloadMB, in: 1...512)
                    Text("Tip: Run multiple times and average. Ensure Low Power Mode is off for consistent results.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Status") {
                    HStack {
                        Text("State")
                        Spacer()
                        Text(vm.status.rawValue.capitalized)
                            .foregroundStyle(vm.status == .running ? .orange : .secondary)
                    }
                    HStack {
                        Button {
                            Task { [weak vm] in
                                await vm?.run()
                            }
                        } label: {
                            Label("Run Benchmarks", systemImage: "play.fill")
                        }
                        .disabled(vm.status == .running)

                        Spacer()
                    }
                }

                Section("Results") {
                    if vm.results.isEmpty {
                        Text("No results yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.results) { result in
                            ResultRowView(result: result)
                        }
                    }
                }
                
                Section("CI Mode") {
                    Stepper("CI Runs: \(vm.ciRuns)", value: $vm.ciRuns, in: 3...9)

                    Button {
                        vm.ciRun()
                    } label: {
                        Label("CI Run (Median Aggregate)", systemImage: "checkmark.seal")
                    }
                    .disabled(vm.status == .running)

                    if !vm.preflightWarnings.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Preflight warnings")
                                .font(.subheadline).fontWeight(.semibold)
                            ForEach(vm.preflightWarnings, id: \.self) { w in
                                Text("• \(w)")
                                    .font(.footnote)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    if !vm.preflightSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Suggestions")
                                .font(.subheadline).fontWeight(.semibold)
                            ForEach(vm.preflightSuggestions, id: \.self) { s in
                                Text("• \(s)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Others") {
                    HStack {
                        Button {
                            vm.saveBaseline()
                        } label: {
                            Label(BaselineStore.shared.existsBaseline() ? "Save Current" : "Save Baseline", systemImage: "tray.and.arrow.down")
                        }
                        .disabled(vm.results.isEmpty)

                        Spacer()

                        Button {
                            vm.compareToBaseline()
                        } label: {
                            Label("Compare", systemImage: "checkmark.seal")
                        }
                        .disabled(vm.results.isEmpty || !BaselineStore.shared.existsBaseline())
                    }
                    
                    NavigationLink(isActive: $vm.showRegression) {
                        RegressionView(checks: vm.regressionChecks)
                    } label: {
                        Label("Regression", systemImage: "exclamationmark.triangle")
                    }
                    .disabled(vm.showRegression)
                    
                    NavigationLink {
                        FpsChartsView(samplesMs: vm.lastFpsSamplesMs)
                    } label: {
                        Label("FPS Charts", systemImage: "chart.bar")
                    }
                    .disabled(vm.lastFpsSamplesMs.isEmpty)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.export()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(vm.results.isEmpty)
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ProfilesView(vm: vm)
                    } label: {
                        Label("Profiles", systemImage: "square.grid.2x2")
                    }
                }
            }
            .sheet(isPresented: $vm.showShareSheet) {
                ShareSheet(items: vm.exportItems)
            }
            .navigationTitle("Mobile Benchmark")
        }
    }
}

