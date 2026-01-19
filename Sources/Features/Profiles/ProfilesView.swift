//
//  ProfilesView.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import SwiftUI

struct ProfilesView: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        List {
            Section("Presets") {
                profileRow(.gaming)
                profileRow(.batteryFriendly)
                profileRow(.ciBaseline)
            }

            Section("Custom") {
                profileRow(.custom)

                if vm.selectedProfile.id == .custom {
                    NavigationLink {
                        CustomProfileEditorView(vm: vm)
                    } label: {
                        Label("Edit Custom Profile", systemImage: "slider.horizontal.3")
                    }
                }
            }

            Section("Current") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(vm.selectedProfile.id.title).font(.headline)
                    Text(vm.selectedProfile.id.subtitle).foregroundStyle(.secondary)

                    Divider()

                    Text("Iterations: \(vm.selectedProfile.iterations)")
                    Text("Payload: \(vm.selectedProfile.payloadMB) MB")
                    Text("FPS: \(Int(vm.selectedProfile.fpsSeconds))s, intensity \(vm.selectedProfile.fpsIntensity)")
                    Text("GPU: \(vm.selectedProfile.gpuElementCount) elems, passes \(vm.selectedProfile.gpuPasses)")
                    Text("Sustained: \(Int(vm.selectedProfile.sustainedSeconds))s")
                    Text("Network: \(vm.selectedProfile.networkURLString)")
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .font(.callout)
            }
        }
        .navigationTitle("Benchmark Profiles")
    }

    @ViewBuilder
    private func profileRow(_ id: BenchmarkProfileID) -> some View {
        Button {
            vm.applyProfile(id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(id.title)
                        .font(.headline)
                    Text(id.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if vm.selectedProfile.id == id {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
