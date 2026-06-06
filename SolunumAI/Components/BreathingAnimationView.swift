import SwiftUI

// MARK: - Phase model

struct BreathPhase: Equatable {
    let label: String
    let instruction: String   // what to do physically
    let tip: String           // short focus cue shown in pill
    let duration: Double
    let scale: CGFloat
    let color: Color
}

// MARK: - Diaphragmatic / Generic circle breathing

struct CircleBreathingView: View {
    let phases: [BreathPhase]
    var isRunning: Bool
    var onPhaseChange: ((String) -> Void)? = nil

    @State private var currentPhaseIndex: Int = 0
    @State private var scale: CGFloat = 0.5
    @State private var phaseProgress: Double = 0
    @State private var timer: Timer? = nil
    @State private var tickTimer: Timer? = nil
    @State private var countdown: Int = 0

    private var currentPhase: BreathPhase { phases[currentPhaseIndex] }

    var body: some View {
        VStack(spacing: 20) {
            // Animated breathing circle
            ZStack {
                // Outer glow rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(currentPhase.color.opacity(0.08 - Double(i) * 0.02), lineWidth: 20)
                        .scaleEffect(scale + CGFloat(i) * 0.06)
                }

                // Main circle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                currentPhase.color.opacity(0.9),
                                currentPhase.color.opacity(0.5),
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 70
                        )
                    )
                    .scaleEffect(scale)
                    .shadow(color: currentPhase.color.opacity(0.4), radius: 12)

                // Center text
                VStack(spacing: 4) {
                    Text(currentPhase.label)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                    if countdown > 0 {
                        Text("\(countdown)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .frame(width: 180, height: 180)

            // Phase progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(currentPhase.color)
                        .frame(width: geo.size.width * phaseProgress)
                        .animation(.linear(duration: 0.1), value: phaseProgress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal)
        }
        .onChange(of: isRunning) { running in
            if running { startCycle() } else { stopCycle() }
        }
        .onDisappear { stopCycle() }
    }

    private func startCycle() {
        currentPhaseIndex = 0
        scale = 0.5
        animatePhase()
    }

    private func stopCycle() {
        timer?.invalidate(); timer = nil
        tickTimer?.invalidate(); tickTimer = nil
        withAnimation(.easeInOut(duration: 0.4)) { scale = 0.5 }
        phaseProgress = 0
        countdown = 0
    }

    private func animatePhase() {
        let phase = phases[currentPhaseIndex]
        countdown = Int(phase.duration)
        phaseProgress = 0
        onPhaseChange?(phase.label)

        withAnimation(.easeInOut(duration: phase.duration)) {
            scale = phase.scale
        }

        var elapsed = 0.0
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { t in
            elapsed += 0.1
            phaseProgress = min(elapsed / phase.duration, 1.0)
            countdown = max(0, Int(phase.duration - elapsed) + 1)
        }

        timer = Timer.scheduledTimer(withTimeInterval: phase.duration, repeats: false) { _ in
            tickTimer?.invalidate()
            phaseProgress = 1.0
            guard isRunning else { return }
            currentPhaseIndex = (currentPhaseIndex + 1) % phases.count
            animatePhase()
        }
    }
}

// MARK: - Box breathing (square animation)

struct BoxBreathingView: View {
    var isRunning: Bool
    var onPhaseChange: ((String) -> Void)? = nil

    @State private var dot = CGPoint(x: 0, y: 0)
    @State private var phase: Int = 0
    @State private var countdown: Int = 4
    @State private var timer: Timer? = nil

    private let labels = ["Nefes Al", "Tut", "Nefes Ver", "Tut"]
    private let boxSize: CGFloat = 150
    private let phaseColors: [Color] = [Color("AppPrimary"), Color("AppSuccess"), Color("AppWarning"), Color("AppDanger")]

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Box
                RoundedRectangle(cornerRadius: 12)
                    .stroke(phaseColors[phase].opacity(0.3), lineWidth: 3)
                    .frame(width: boxSize, height: boxSize)

                // Side highlights per phase
                RoundedRectangle(cornerRadius: 12)
                    .stroke(phaseColors[phase], lineWidth: 3)
                    .frame(width: boxSize, height: boxSize)
                    .opacity(0.6)

                // Moving dot
                Circle()
                    .fill(phaseColors[phase])
                    .frame(width: 20, height: 20)
                    .shadow(color: phaseColors[phase].opacity(0.5), radius: 6)
                    .offset(x: dot.x, y: dot.y)
                    .animation(.linear(duration: 4), value: dot)

                // Center label
                VStack(spacing: 2) {
                    Text(labels[phase])
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    Text("\(countdown)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(phaseColors[phase])
                }
            }
            .frame(width: boxSize + 40, height: boxSize + 40)
        }
        .onChange(of: isRunning) { running in
            if running { startBox() } else { stopBox() }
        }
        .onDisappear { stopBox() }
    }

    private func corners() -> [CGPoint] {
        let h = boxSize / 2
        return [
            CGPoint(x: -h, y: -h),  // top-left
            CGPoint(x:  h, y: -h),  // top-right
            CGPoint(x:  h, y:  h),  // bottom-right
            CGPoint(x: -h, y:  h),  // bottom-left
        ]
    }

    private func startBox() {
        phase = 0
        let c = corners()
        dot = c[0]
        animateSegment(to: c[1], phaseIdx: 0)
    }

    private func stopBox() {
        timer?.invalidate(); timer = nil
        countdown = 4
    }

    private func animateSegment(to target: CGPoint, phaseIdx: Int) {
        phase = phaseIdx
        countdown = 4
        dot = target
        onPhaseChange?(labels[phaseIdx])

        var elapsed = 0.0
        let tick = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            elapsed += 1
            countdown = max(1, 4 - Int(elapsed))
        }
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            tick.invalidate()
            guard isRunning else { return }
            let next = (phaseIdx + 1) % 4
            let c = corners()
            animateSegment(to: c[(next + 1) % 4], phaseIdx: next)
        }
    }
}

// MARK: - Controlled Cough steps

struct ControlledCoughView: View {
    let steps = [
        ("1", "Derin bir nefes alın ve 2-3 saniye tutun."),
        ("2", "Ağzınızı kapatın ve diyaframınızla baskı hissedin."),
        ("3", "Ağzınızı açın ve 2 kısa, güçlü öksürük yapın."),
        ("4", "Burnunuzdan yavaşça nefes alın."),
        ("5", "Gerekirse tekrarlayın, yorulduğunuzda durun."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(steps, id: \.0) { num, text in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color("AppPrimary"))
                            .frame(width: 32, height: 32)
                        Text(num)
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                    }
                    Text(text)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preset phases

extension BreathPhase {
    static let diaphragmatic: [BreathPhase] = [
        BreathPhase(
            label: "Nefes Al",
            instruction: "Burnundan yavaşça nefes al.\nKarnın şişmeli, göğsün sabit kalmalı.",
            tip: "Karın şişiyor ↑",
            duration: 4, scale: 0.9, color: Color("AppPrimary")),
        BreathPhase(
            label: "Nefes Ver",
            instruction: "Ağzından yavaşça ver.\nKarnını içeri çek, tüm havayı boşalt.",
            tip: "Karın içe ↓",
            duration: 6, scale: 0.5, color: Color("AppSuccess")),
    ]

    static let fourSevenEight: [BreathPhase] = [
        BreathPhase(
            label: "Nefes Al",
            instruction: "Burnundan derin nefes al.\nAkciğerlerini tamamen doldur.",
            tip: "4 say →",
            duration: 4, scale: 0.9, color: Color("AppPrimary")),
        BreathPhase(
            label: "Tut",
            instruction: "Nefesini rahatça tut.\nVücudun oksijeni emsin, zorlanma.",
            tip: "Sakin tut →",
            duration: 7, scale: 0.9, color: Color("AppWarning")),
        BreathPhase(
            label: "Nefes Ver",
            instruction: "Ağzından eşit hızda ver.\nTüm stresi ve gerginliği bırak.",
            tip: "8 say →",
            duration: 8, scale: 0.4, color: Color("AppSuccess")),
    ]

    static let pursedLip: [BreathPhase] = [
        BreathPhase(
            label: "Burundan Al",
            instruction: "Burnundan 2 sayarak nefes al.\nOmuzların gevşek kalsın.",
            tip: "Burundan ↑",
            duration: 2, scale: 0.85, color: Color("AppPrimary")),
        BreathPhase(
            label: "Büzük Dudak",
            instruction: "Dudaklarını ıslık gibi büz.\n4 sayarak yavaş ve kontrollü ver.",
            tip: "Dudaklar büzük →",
            duration: 4, scale: 0.45, color: Color("AppWarning")),
    ]
}
