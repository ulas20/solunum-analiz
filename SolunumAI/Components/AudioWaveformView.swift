import SwiftUI

// MARK: - Real-time Audio Waveform

struct AudioWaveformView: View {
    let samples: [Float]        // 0.0 – 1.0 normalised amplitude values
    var isRecording: Bool = false
    var color: Color = Color("AppPrimary")
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(samples.enumerated()), id: \.offset) { idx, sample in
                    RoundedRectangle(cornerRadius: barWidth / 2)
                        .fill(barColor(for: sample, index: idx))
                        .frame(
                            width: barWidth,
                            height: max(4, CGFloat(sample) * geo.size.height)
                        )
                        .animation(.easeOut(duration: 0.05), value: sample)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func barColor(for sample: Float, index: Int) -> Color {
        let intensity = Double(sample)
        if !isRecording { return Color(.systemGray4) }
        return color.opacity(0.4 + intensity * 0.6)
    }
}

// MARK: - Static Waveform (idle state)

struct IdleWaveformView: View {
    @State private var phase: Double = 0

    let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<50, id: \.self) { i in
                    let height = idleHeight(for: i, phase: phase, total: geo.size.height)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color("AppPrimary").opacity(0.25))
                        .frame(width: 3, height: height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .onReceive(timer) { _ in
            phase += 0.08
        }
    }

    private func idleHeight(for index: Int, phase: Double, total: CGFloat) -> CGFloat {
        let x  = Double(index) / 50.0
        let v  = sin(x * .pi * 4 + phase) * 0.3 + sin(x * .pi * 2 + phase * 0.7) * 0.15 + 0.1
        return max(4, CGFloat(v) * total * 0.8)
    }
}

// MARK: - Level Meter Ring

struct AudioLevelRingView: View {
    let level: Float   // 0.0 – 1.0

    @State private var animLevel: Double = 0

    private var ringColor: Color {
        switch animLevel {
        case 0..<0.15: return Color(.systemGray4)
        case 0.15..<0.60: return Color("AppSuccess")
        default: return Color("AppWarning")
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 6)

            Circle()
                .trim(from: 0, to: animLevel)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.08), value: animLevel)
        }
        .onChange(of: level) { newLevel in
            animLevel = Double(newLevel)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        AudioWaveformView(samples: (0..<50).map { _ in Float.random(in: 0.1...0.9) }, isRecording: true)
            .frame(height: 60)
            .padding()

        IdleWaveformView()
            .frame(height: 60)
            .padding()

        AudioLevelRingView(level: 0.6)
            .frame(width: 80, height: 80)
    }
    .padding()
}
