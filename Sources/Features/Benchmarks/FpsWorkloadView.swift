//
//  FpsWorkloadView.swift
//  MobileBenchmark
//
//  Created by Farooq Mulla on 1/18/26.
//

import SwiftUI

struct FpsWorkloadView: View {
    @State private var angle: Double = 0
    let intensity: Int // 1..10 (higher = heavier)

    var body: some View {
        ZStack {
            TimelineView(.animation) { _ in
                ZStack {
                    ForEach(0..<(intensity * 25), id: \.self) { i in
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(angle + Double(i) * 7))
                            .offset(x: CGFloat((i % 10) * 10), y: CGFloat((i / 10) * 10))
                            .opacity(0.15)
                    }

                    Text("FPS Workload")
                        .font(.headline)
                }
                .padding()
                .onAppear {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        angle = 360
                    }
                }
            }
        }
    }
}

