//
//  GpuKernels.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

#include <metal_stdlib>
using namespace metal;

kernel void saxpy(device const float* inX [[buffer(0)]],
                  device const float* inY [[buffer(1)]],
                  device float* out   [[buffer(2)]],
                  constant float& a   [[buffer(3)]],
                  uint gid            [[thread_position_in_grid]]) {
    out[gid] = a * inX[gid] + inY[gid];
}
