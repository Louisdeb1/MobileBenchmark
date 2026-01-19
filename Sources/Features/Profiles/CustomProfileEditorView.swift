//
//  CustomProfileEditorView.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import SwiftUI
import Foundation

struct CustomProfileEditorView: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        Form {
            Section("General") {
                Stepper("Iterations: \(vm.selectedProfile.iterations)",
                        value: Binding(get: { vm.selectedProfile.iterations },
                                       set: { newValue in vm.updateCustom { profile in profile.iterations = newValue } }),
                        in: 1...10)

                Stepper("Payload: \(vm.selectedProfile.payloadMB) MB",
                        value: Binding(get: { vm.selectedProfile.payloadMB },
                                       set: { newValue in vm.updateCustom { profile in profile.payloadMB = newValue } }),
                        in: 1...512)
            }

            Section("FPS/Jank") {
                Stepper("Duration: \(Int(vm.selectedProfile.fpsSeconds))s",
                        value: Binding(get: { Int(vm.selectedProfile.fpsSeconds) },
                                       set: { newValue in vm.updateCustom { profile in profile.fpsSeconds = Double(newValue) } }),
                        in: 3...30)

                Stepper("Intensity: \(vm.selectedProfile.fpsIntensity)",
                        value: Binding(get: { vm.selectedProfile.fpsIntensity },
                                       set: { newValue in vm.updateCustom { profile in profile.fpsIntensity = newValue } }),
                        in: 1...10)
            }

            Section("GPU") {
                Stepper("Element Count: \(vm.selectedProfile.gpuElementCount)",
                        value: Binding(get: { vm.selectedProfile.gpuElementCount },
                                       set: { newValue in vm.updateCustom { profile in profile.gpuElementCount = newValue } }),
                        in: 1_048_576...16_777_216,
                        step: 1_048_576)

                Stepper("Passes: \(vm.selectedProfile.gpuPasses)",
                        value: Binding(get: { vm.selectedProfile.gpuPasses },
                                       set: { newValue in vm.updateCustom { profile in profile.gpuPasses = newValue } }),
                        in: 5...100)
            }

            Section("Sustained/Thermal") {
                Stepper("Duration: \(Int(vm.selectedProfile.sustainedSeconds))s",
                        value: Binding(get: { Int(vm.selectedProfile.sustainedSeconds) },
                                       set: { newValue in vm.updateCustom { profile in profile.sustainedSeconds = Double(newValue) } }),
                        in: 5...120)
            }

            Section("Network") {
                TextField("Download URL", text: Binding(
                    get: { vm.selectedProfile.networkURLString },
                    set: { newValue in vm.updateCustom { profile in profile.networkURLString = newValue } }
                ))
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }
        }
        .navigationTitle("Edit Custom Profile")
    }
}
