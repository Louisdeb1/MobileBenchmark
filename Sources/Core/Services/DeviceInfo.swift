//
//  DeviceInfo.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation
import UIKit

enum DeviceInfo {
    static func modelIdentifier() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { ptr in
                String(cString: ptr)
            }
        }
        return machine
    }

    @MainActor static func osVersion() -> String {
        UIDevice.current.systemVersion
    }

    @MainActor static func deviceName() -> String {
        UIDevice.current.name
    }

    static func processorCount() -> Int {
        ProcessInfo.processInfo.processorCount
    }

    static func physicalMemoryMB() -> Double {
        Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0)
    }

    @MainActor static func summaryDictionary() -> [String: String] {
        [
            "deviceName": deviceName(),
            "modelIdentifier": modelIdentifier(),
            "iOS": osVersion(),
            "cores": "\(processorCount())",
            "physicalMemoryMB": String(format: "%.0f", physicalMemoryMB())
        ]
    }
}

