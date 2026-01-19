//
//  GpuBenchmark.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import Foundation
import Metal

struct GpuBenchmark: Benchmark {
    let name: String = "GPU: Metal Compute (SAXPY)"
    let category: BenchmarkCategory = .cpu // or create .gpu if you want

    private let elementCount: Int
    private let passes: Int

    /// elementCount: number of float elements processed each pass
    /// passes: number of repeated kernel dispatches
    init(elementCount: Int = 8_388_608, passes: Int = 30) { // ~32MB per buffer
        self.elementCount = elementCount
        self.passes = passes
    }

    func run(context: BenchmarkContext) async throws -> BenchmarkResult {
        let started = Metrics.now()

        guard let device = MTLCreateSystemDefaultDevice() else {
            throw NSError(domain: "GpuBenchmark", code: 1, userInfo: [NSLocalizedDescriptionKey: "Metal not supported"])
        }
        guard let queue = device.makeCommandQueue() else {
            throw NSError(domain: "GpuBenchmark", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create command queue"])
        }

        let library = try device.makeDefaultLibrary(bundle: .main)
        guard let fn = library.makeFunction(name: "saxpy") else {
            throw NSError(domain: "GpuBenchmark", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing Metal function saxpy"])
        }
        let pipeline = try await device.makeComputePipelineState(function: fn)

        // Buffers
        let bytes = elementCount * MemoryLayout<Float>.size
        guard let inX = device.makeBuffer(length: bytes, options: [.storageModeShared]),
              let inY = device.makeBuffer(length: bytes, options: [.storageModeShared]),
              let out = device.makeBuffer(length: bytes, options: [.storageModeShared]) else {
            throw NSError(domain: "GpuBenchmark", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate buffers"])
        }

        // init input data (CPU)
        let ax: Float = 2.5
        let xPtr = inX.contents().bindMemory(to: Float.self, capacity: elementCount)
        let yPtr = inY.contents().bindMemory(to: Float.self, capacity: elementCount)
        for i in 0..<elementCount {
            xPtr[i] = Float(i % 1024) * 0.001
            yPtr[i] = Float((i * 7) % 1024) * 0.001
        }

        // constant buffer for scalar a
        var a = ax

        // Warm-up (optional)
        _ = try runPass(device: device, queue: queue, pipeline: pipeline,
                        inX: inX, inY: inY, out: out, a: &a,
                        elementCount: elementCount)

        // Timed passes
        let elapsedMs = try timedMs {
            for _ in 0..<passes {
                _ = try runPass(device: device, queue: queue, pipeline: pipeline,
                                inX: inX, inY: inY, out: out, a: &a,
                                elementCount: elementCount)
            }
        }

        // Simple checksum to ensure results are used
        let outPtr = out.contents().bindMemory(to: Float.self, capacity: elementCount)
        let checksum = Double(outPtr[0] + outPtr[elementCount / 2] + outPtr[elementCount - 1])

        let ended = Metrics.now()

        let totalElements = Double(elementCount) * Double(passes)
        let seconds = max(0.000_001, elapsedMs / 1000.0)
        let elementsPerSec = totalElements / seconds

        let totalMB = (Double(bytes) * 3.0 * Double(passes)) / (1024.0 * 1024.0) // X+Y+Out each pass
        let approxMBps = totalMB / seconds

        return BenchmarkResult(
            name: name,
            category: category,
            startedAt: started,
            endedAt: ended,
            metrics: [
                .init(key: "Elapsed", value: elapsedMs, unit: .ms),
                .init(key: "Elements/sec", value: elementsPerSec, unit: .opsPerSec),
                .init(key: "Approx Throughput", value: approxMBps, unit: .mbPerSec),
                .init(key: "Checksum", value: checksum, unit: .bytes)
            ],
            notes: "Higher Elements/sec and MB/s is better. elementCount=\(elementCount), passes=\(passes)"
        )
    }

    private func runPass(device: MTLDevice,
                         queue: MTLCommandQueue,
                         pipeline: MTLComputePipelineState,
                         inX: MTLBuffer,
                         inY: MTLBuffer,
                         out: MTLBuffer,
                         a: inout Float,
                         elementCount: Int) throws -> Void {

        guard let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeComputeCommandEncoder() else {
            throw NSError(domain: "GpuBenchmark", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to create encoder"])
        }

        enc.setComputePipelineState(pipeline)
        enc.setBuffer(inX, offset: 0, index: 0)
        enc.setBuffer(inY, offset: 0, index: 1)
        enc.setBuffer(out, offset: 0, index: 2)
        enc.setBytes(&a, length: MemoryLayout<Float>.size, index: 3)

        let w = pipeline.threadExecutionWidth
        let threadsPerTG = MTLSize(width: w, height: 1, depth: 1)
        let threads = MTLSize(width: elementCount, height: 1, depth: 1)

        enc.dispatchThreads(threads, threadsPerThreadgroup: threadsPerTG)
        enc.endEncoding()

        cmd.commit()
        cmd.waitUntilCompleted()
    }

    private func timedMs(_ block: () throws -> Void) throws -> Double {
        let start = DispatchTime.now().uptimeNanoseconds
        try block()
        let end = DispatchTime.now().uptimeNanoseconds
        return Double(end - start) / 1_000_000.0
    }
}

