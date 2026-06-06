import SwiftUI

// MARK: - Circular Risk Gauge

struct RiskGaugeView: View {
    let value: Double       // 0.0 – 1.0
    var size: CGFloat = 200

    @State private var animatedValue: Double = 0

    private var riskLevel: RiskLevel {
        switch value {
        case ..<0.40: return .low
        case 0.40..<0.50: return .moderate
        default: return .high
        }
    }

    private var gaugeColor: Color {
        switch riskLevel {
        case .low:      return Color("AppSuccess")
        case .moderate: return Color("AppWarning")
        case .high:     return Color("AppDanger")
        }
    }

    private var percentage: Int { Int(animatedValue * 100) }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color(.systemGray5), style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
                .rotationEffect(.degrees(135))

            // Gradient value arc
            Circle()
                .trim(from: 0, to: 0.75 * animatedValue)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [gaugeColor.opacity(0.7), gaugeColor]),
                        center: .center,
                        startAngle: .degrees(135),
                        endAngle: .degrees(135 + 270 * animatedValue)
                    ),
                    style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round)
                )
                .rotationEffect(.degrees(135))
                .shadow(color: gaugeColor.opacity(0.4), radius: 6)

            // Center text
            VStack(spacing: 4) {
                Text("\(percentage)%")
                    .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(riskLevel.rawValue)
                    .font(.system(size: size * 0.07, weight: .semibold))
                    .foregroundColor(gaugeColor)
                    .multilineTextAlignment(.center)

                Text(riskLevel.emoji)
                    .font(.system(size: size * 0.1))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { newVal in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedValue = newVal
            }
        }
    }
}

// MARK: - Mini Score Bar (for model breakdown)

struct ScoreBarView: View {
    let label: String
    let value: Double
    let color: Color

    @State private var animatedValue: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f%%", animatedValue * 100))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * animatedValue, height: 8)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                animatedValue = value
            }
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        RiskGaugeView(value: 0.28, size: 180)
        RiskGaugeView(value: 0.45, size: 180)
        RiskGaugeView(value: 0.72, size: 180)
        ScoreBarView(label: "Gribal Rahatsızlık", value: 0.35, color: Color("AppWarning"))
            .padding()
    }
    .padding()
}
