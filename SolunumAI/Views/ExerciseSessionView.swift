import SwiftUI

// MARK: - Exercise Entry (Prep → Session)

struct ExerciseSessionView: View {
    let exercise: BreathingExercise
    @ObservedObject var progress: ExerciseProgressService
    @Environment(\.dismiss) private var dismiss

    @State private var showSession = false

    var body: some View {
        if showSession {
            ActiveSessionView(exercise: exercise, progress: progress, dismiss: { dismiss() })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        } else {
            ExercisePrepView(exercise: exercise, onStart: {
                withAnimation(.easeInOut(duration: 0.35)) { showSession = true }
            }, onDismiss: { dismiss() })
        }
    }
}

// MARK: - Prep / How-to Screen

private struct ExercisePrepView: View {
    let exercise: BreathingExercise
    let onStart: () -> Void
    let onDismiss: () -> Void

    private var accentColor: Color { Color(exercise.color) }
    private var prep: ExercisePrep { ExercisePrep.for(exercise.type) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color("AppBackground").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Hero
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [accentColor.opacity(0.9), accentColor.opacity(0.5)],
                                startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 220)

                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: exerciseIcon)
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            Text(exercise.title)
                                .font(.title.weight(.bold))
                                .foregroundColor(.white)
                            Text(exercise.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(24)
                    }

                    VStack(alignment: .leading, spacing: 28) {

                        // Stats row
                        HStack(spacing: 0) {
                            prepStat(icon: "clock", label: "Süre", value: durationStr)
                            Divider().frame(height: 36)
                            prepStat(icon: "arrow.clockwise", label: "Ritim", value: prep.rhythm)
                            Divider().frame(height: 36)
                            prepStat(icon: "chart.bar.fill", label: "Seviye", value: prep.level)
                        }
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 6)

                        // Fayda
                        sectionHeader("Ne işe yarar?", icon: "sparkles")
                        Text(exercise.benefits)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineSpacing(4)

                        // Hazırlık
                        sectionHeader("Başlamadan önce", icon: "checklist")
                        VStack(spacing: 10) {
                            ForEach(Array(prep.setup.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(accentColor.opacity(0.12))
                                            .frame(width: 30, height: 30)
                                        Text("\(i+1)")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(accentColor)
                                    }
                                    Text(step)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                }
                            }
                        }

                        // Nefes adımları
                        sectionHeader("Nefes döngüsü", icon: "lungs.fill")
                        VStack(spacing: 8) {
                            ForEach(prep.breathSteps) { step in
                                BreathStepRow(step: step, accentColor: accentColor)
                            }
                        }

                        // İpuçları
                        if !prep.tips.isEmpty {
                            sectionHeader("İpuçları", icon: "lightbulb.fill")
                            VStack(spacing: 8) {
                                ForEach(prep.tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(accentColor)
                                            .font(.subheadline)
                                        Text(tip)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                }
                            }
                        }

                        // Başla
                        Button(action: onStart) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Egzersize Başla")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentColor)
                            .cornerRadius(16)
                            .shadow(color: accentColor.opacity(0.4), radius: 10, y: 4)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Kapat butonu
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding(.top, 52)
            .padding(.leading, 20)
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(accentColor)
            Text(title)
                .font(.headline)
        }
    }

    @ViewBuilder
    private func prepStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(accentColor)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var durationStr: String {
        let m = exercise.duration / 60
        let s = exercise.duration % 60
        return s == 0 ? "\(m) dk" : "\(m):\(String(format:"%02d",s))"
    }

    private var exerciseIcon: String {
        switch exercise.type {
        case .diaphragmatic:   return "lungs.fill"
        case .fourSevenEight:  return "4.circle.fill"
        case .pursedLip:       return "mouth.fill"
        case .boxBreathing:    return "square.fill"
        case .controlledCough: return "waveform.path"
        }
    }
}

private struct BreathStepRow: View {
    let step: BreathStepInfo
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // Phase color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(step.color)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(step.phase)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(step.color)
                    Spacer()
                    Text(step.duration)
                        .font(.caption.weight(.bold))
                        .foregroundColor(step.color)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(step.color.opacity(0.12))
                        .cornerRadius(8)
                }
                Text(step.desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4)
    }
}

// MARK: - Active Session

private struct ActiveSessionView: View {
    let exercise: BreathingExercise
    @ObservedObject var progress: ExerciseProgressService
    let dismiss: () -> Void

    @State private var isRunning      = false
    @State private var elapsed: TimeInterval = 0
    @State private var cycleCount     = 0
    @State private var timer: Timer?
    @State private var showCompletion = false
    @State private var sessionResult: SessionResult?
    @State private var currentPhase: BreathPhase?

    private var accentColor: Color  { Color(exercise.color) }
    private var totalDuration: Double { Double(exercise.duration) }
    private var overallProgress: Double { Swift.min(elapsed / totalDuration, 1.0) }
    private var remainingSecs: Int  { Swift.max(0, Int(totalDuration - elapsed)) }

    private var circlePhases: [BreathPhase] {
        switch exercise.type {
        case .diaphragmatic:  return BreathPhase.diaphragmatic
        case .fourSevenEight: return BreathPhase.fourSevenEight
        case .pursedLip:      return BreathPhase.pursedLip
        default: return []
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [accentColor.opacity(0.15), Color("AppBackground"), Color("AppBackground")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Top bar ───────────────────────────────────────────
                HStack {
                    Button { handleClose() } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2).foregroundColor(.secondary)
                    }
                    Spacer()
                    VStack(spacing: 2) {
                        Text(exercise.title).font(.headline)
                        // Overall progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(.systemGray5))
                                Capsule().fill(accentColor)
                                    .frame(width: geo.size.width * overallProgress)
                                    .animation(.linear(duration: 0.5), value: overallProgress)
                            }
                        }
                        .frame(width: 120, height: 4)
                    }
                    Spacer()
                    // Time remaining
                    Text(timeStr(remainingSecs))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(accentColor)
                        .frame(width: 48)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)

                // ── Phase indicator strip ─────────────────────────────
                if !circlePhases.isEmpty {
                    PhaseStripView(phases: circlePhases, currentPhase: currentPhase)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }

                // ── Main animation ────────────────────────────────────
                ZStack {
                    switch exercise.type {
                    case .diaphragmatic:
                        CircleBreathingView(phases: BreathPhase.diaphragmatic, isRunning: isRunning,
                            onPhaseChange: onPhase(firstLabel: "Nefes Al"))
                    case .fourSevenEight:
                        CircleBreathingView(phases: BreathPhase.fourSevenEight, isRunning: isRunning,
                            onPhaseChange: onPhase(firstLabel: "Nefes Al"))
                    case .pursedLip:
                        CircleBreathingView(phases: BreathPhase.pursedLip, isRunning: isRunning,
                            onPhaseChange: onPhase(firstLabel: "Burundan Al"))
                    case .boxBreathing:
                        BoxBreathingView(isRunning: isRunning, onPhaseChange: { label in
                            haptic()
                            if label == "Nefes Al" && isRunning { cycleCount += 1 }
                        })
                    case .controlledCough:
                        AnimatedCoughGuideView(isRunning: isRunning)
                    }
                }
                .frame(maxWidth: .infinity)

                // ── Instruction panel ─────────────────────────────────
                Group {
                    if exercise.type == .controlledCough || exercise.type == .boxBreathing {
                        // These have built-in instructions
                        Spacer(minLength: 8)
                    } else {
                        PhaseInstructionView(phase: currentPhase, isRunning: isRunning, accentColor: accentColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                    }
                }

                Spacer()

                // ── Stats row ─────────────────────────────────────────
                HStack(spacing: 24) {
                    sessionStat(value: "\(cycleCount)", label: "tur", icon: "arrow.clockwise")
                    sessionStat(value: String(format: "%.1f", elapsed / 60), label: "dakika", icon: "clock")
                    sessionStat(value: "+\(estimatedXP) XP", label: "kazanç", icon: "bolt.fill", color: .yellow)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // ── Controls ──────────────────────────────────────────
                HStack(spacing: 36) {
                    // Reset
                    controlBtn(icon: "arrow.counterclockwise", color: .secondary, bg: Color(.systemGray5)) {
                        resetSession()
                    }

                    // Play / Pause
                    Button { isRunning ? pauseSession() : startSession() } label: {
                        ZStack {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 76, height: 76)
                                .shadow(color: accentColor.opacity(0.45), radius: 14)
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: isRunning ? 0 : 2)
                        }
                    }

                    // Finish
                    controlBtn(icon: "checkmark", color: Color("AppSuccess"), bg: Color("AppSuccess").opacity(0.15)) {
                        finishSession()
                    }
                }
                .padding(.bottom, 44)
            }
        }
        .fullScreenCover(isPresented: $showCompletion) {
            if let r = sessionResult {
                ExerciseCompletionView(
                    exercise: exercise, result: r,
                    minutesDone: elapsed / 60, cyclesDone: cycleCount
                ) { showCompletion = false; dismiss() }
            }
        }
        .onDisappear { cleanup() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sessionStat(value: String, label: String, icon: String, color: Color = Color("AppPrimary")) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon).font(.caption2).foregroundColor(color)
                Text(value).font(.subheadline.weight(.bold))
            }
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func controlBtn(icon: String, color: Color, bg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundColor(color)
                .frame(width: 52, height: 52)
                .background(bg)
                .clipShape(Circle())
        }
    }

    private func onPhase(firstLabel: String) -> (String) -> Void {
        { label in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                currentPhase = circlePhases.first { $0.label == label }
            }
            haptic()
            if label == firstLabel && isRunning { cycleCount += 1 }
        }
    }

    private var estimatedXP: Int { Int(elapsed / 60 * 10) + 20 }

    private func startSession() {
        isRunning = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            elapsed += 0.5
            if elapsed >= totalDuration { finishSession() }
        }
    }

    private func pauseSession() {
        isRunning = false; timer?.invalidate(); timer = nil
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func resetSession() {
        pauseSession(); elapsed = 0; cycleCount = 0
        withAnimation { currentPhase = nil }
    }

    private func finishSession() {
        cleanup()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        sessionResult = progress.completeSession(
            exerciseId: exercise.id.uuidString,
            exerciseTitle: exercise.title,
            durationMinutes: Swift.max(elapsed / 60, 0.5)
        )
        showCompletion = true
    }

    private func handleClose() {
        if elapsed > 30 { finishSession() } else { dismiss() }
    }

    private func cleanup() { isRunning = false; timer?.invalidate(); timer = nil }
    private func haptic() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    private func timeStr(_ s: Int) -> String { String(format: "%02d:%02d", s/60, s%60) }
}

// MARK: - Phase Strip (compact, horizontal)

private struct PhaseStripView: View {
    let phases: [BreathPhase]
    let currentPhase: BreathPhase?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(phases.enumerated()), id: \.offset) { i, phase in
                let active = phase == currentPhase
                HStack(spacing: active ? 5 : 0) {
                    Circle()
                        .fill(active ? phase.color : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                    if active {
                        Text(phase.label)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(phase.color)
                            .fixedSize()
                    }
                }
                .padding(.horizontal, active ? 10 : 6)
                .padding(.vertical, 6)
                .background(active ? phase.color.opacity(0.12) : Color(.systemGray6))
                .cornerRadius(20)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: active)

                if i < phases.count - 1 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(.systemGray4))
                }
            }
            Spacer()
        }
    }
}

// MARK: - Phase Instruction Panel

private struct PhaseInstructionView: View {
    let phase: BreathPhase?
    let isRunning: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            if let p = phase {
                VStack(spacing: 0) {
                    // Big phase label
                    Text(p.label)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(p.color)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 6)

                    // Instruction text
                    Text(p.instruction)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)

                    // Tip chip
                    HStack(spacing: 6) {
                        Image(systemName: "hand.point.right.fill")
                            .font(.caption)
                            .foregroundColor(p.color)
                        Text(p.tip)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(p.color)
                        Spacer()
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .shadow(color: p.color.opacity(0.18), radius: 10, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(p.color.opacity(0.25), lineWidth: 1.5)
                )
                .id(p.label)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal:   .opacity
                ))

            } else if !isRunning {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2).foregroundColor(accentColor)
                    Text("Başlatmak için ▶ düğmesine bas")
                        .font(.subheadline).foregroundColor(.secondary)
                    Spacer()
                }
                .padding(18)
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(18)
                .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: phase?.label)
    }
}

// MARK: - Animated Cough Guide

private struct AnimatedCoughGuideView: View {
    var isRunning: Bool

    private struct CoughStep: Identifiable {
        let id = UUID()
        let icon: String; let title: String; let detail: String; let color: Color; let duration: Double
    }
    private let steps: [CoughStep] = [
        CoughStep(icon: "lungs.fill",         title: "Derin Nefes Al",    detail: "Burnundan yavaş ve derin nefes al.\n2–3 saniye tut.",                color: Color("AppPrimary"), duration: 5),
        CoughStep(icon: "hand.raised.fill",   title: "Diyafram Baskısı",  detail: "Ağzını kapat.\nKarın kaslarınla içe doğru bas, baskıyı hisset.",    color: Color("AppWarning"), duration: 4),
        CoughStep(icon: "waveform.path",      title: "Kısa Öksürük",      detail: "Ağzını aç ve 2 kısa, güçlü öksürük yap.\n\"Huf-Huf\" dercesine.",  color: Color("AppDanger"),  duration: 4),
        CoughStep(icon: "leaf.fill",          title: "Toparlan",          detail: "Burnundan yavaşça nefes al.\nOmuzlarını bırak, sakinleş.",           color: Color("AppSuccess"), duration: 4),
        CoughStep(icon: "arrow.clockwise",    title: "Tekrarla",          detail: "Gerekirse döngüyü tekrarla.\nYorulduğunda dur ve dinlen.",           color: Color("AppPrimary"), duration: 5),
    ]

    @State private var active = 0
    @State private var phaseProgress: Double = 0
    @State private var autoTimer: Timer?
    @State private var tickTimer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            // Step dots
            HStack(spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                    ZStack {
                        Circle()
                            .fill(i == active ? step.color : Color(.systemGray5))
                            .frame(width: i == active ? 36 : 10, height: i == active ? 36 : 10)
                        if i == active {
                            Text("\(i+1)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                        }
                    }
                    .animation(.spring(response: 0.4), value: active)
                    if i < steps.count - 1 {
                        Rectangle()
                            .fill(i < active ? steps[i].color : Color(.systemGray5))
                            .frame(height: 2)
                            .animation(.easeInOut, value: active)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Current step
            let s = steps[active]
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(s.color.opacity(0.15), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: phaseProgress)
                        .stroke(s.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: phaseProgress)
                    Image(systemName: s.icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(s.color)
                }
                .frame(width: 100, height: 100)

                Text(s.title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(s.color)

                Text(s.detail)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
            .id(active)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: active)
            .padding(20)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(20)
            .shadow(color: s.color.opacity(0.12), radius: 10, y: 3)
            .padding(.horizontal, 20)

            // Manual nav
            HStack {
                Button { goTo(active - 1) } label: {
                    Label("Önceki", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .disabled(active == 0)
                Spacer()
                Text("Adım \(active+1) / \(steps.count)")
                    .font(.caption).foregroundColor(.secondary)
                Spacer()
                Button { goTo(active + 1) } label: {
                    Label("Sonraki", systemImage: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(s.color)
                        .environment(\.layoutDirection, .rightToLeft)
                }
                .disabled(active == steps.count - 1)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .onChange(of: isRunning) { r in r ? startAuto() : stopAuto() }
        .onDisappear { stopAuto() }
    }

    private func goTo(_ i: Int) {
        guard steps.indices.contains(i) else { return }
        stopAuto()
        withAnimation { active = i; phaseProgress = 0 }
        if isRunning { startAuto() }
    }

    private func startAuto() {
        active = 0; phaseProgress = 0
        advanceStep()
    }

    private func advanceStep() {
        let step = steps[active]
        phaseProgress = 0
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        var elapsed = 0.0
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsed += 0.1
            phaseProgress = Swift.min(elapsed / step.duration, 1.0)
        }
        autoTimer = Timer.scheduledTimer(withTimeInterval: step.duration, repeats: false) { _ in
            tickTimer?.invalidate()
            guard isRunning else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                active = (active + 1) % steps.count
                phaseProgress = 0
            }
            advanceStep()
        }
    }

    private func stopAuto() {
        autoTimer?.invalidate(); autoTimer = nil
        tickTimer?.invalidate(); tickTimer = nil
    }
}

// MARK: - Completion Screen

struct ExerciseCompletionView: View {
    let exercise: BreathingExercise
    let result: SessionResult
    let minutesDone: Double
    let cyclesDone: Int
    let onDismiss: () -> Void

    @State private var showXP    = false
    @State private var showStats = false
    @State private var showAchs  = false
    @State private var xpCounter = 0

    private var accentColor: Color { Color(exercise.color) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [accentColor.opacity(0.2), Color("AppBackground")],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle().fill(accentColor.opacity(0.12)).frame(width: 120, height: 120)
                        Image(systemName: "trophy.fill").font(.system(size: 52)).foregroundColor(accentColor)
                            .scaleEffect(showXP ? 1.0 : 0.2)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: showXP)
                    }
                    .padding(.top, 48)

                    Text("Harika iş!").font(.largeTitle.weight(.bold))
                    Text("\(exercise.title) tamamlandı").font(.subheadline).foregroundColor(.secondary)

                    if showXP {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill").foregroundColor(.yellow).font(.title2)
                            Text("+\(xpCounter) XP")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    if showStats {
                        HStack(spacing: 12) {
                            completionStat(icon: "clock.fill",      label: "Süre",   value: String(format: "%.1f dk", minutesDone), color: accentColor)
                            completionStat(icon: "arrow.clockwise", label: "Tur",    value: "\(cyclesDone)",                        color: accentColor)
                            completionStat(icon: "list.number",     label: "Toplam", value: "\(result.totalSessions)",              color: accentColor)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        if result.newStreak > 1 {
                            Label("\(result.newStreak) günlük seri! 🔥", systemImage: "flame.fill")
                                .font(.headline).foregroundColor(.orange)
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background(Color.orange.opacity(0.12)).cornerRadius(20)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    if showAchs && !result.newAchievements.isEmpty {
                        VStack(spacing: 10) {
                            Label("Yeni Rozetler!", systemImage: "medal.fill")
                                .font(.headline).foregroundColor(.yellow)
                            ForEach(result.newAchievements) { ach in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color.yellow.opacity(0.15)).frame(width: 46, height: 46)
                                        Image(systemName: ach.icon).font(.system(size: 20)).foregroundColor(.yellow)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(ach.title).font(.subheadline.weight(.semibold))
                                        Text(ach.desc).font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("+\(ach.xpReward) XP").font(.caption.weight(.bold)).foregroundColor(.yellow)
                                }
                                .padding(12).background(Color(.systemBackground)).cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 4)
                            }
                        }
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Button(action: onDismiss) {
                        Text("Tamam").font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(accentColor).cornerRadius(16)
                    }
                    .padding(.horizontal).padding(.bottom, 40)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(0.2))  { showXP = true }
            let target = result.xpEarned
            Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { t in
                xpCounter = Swift.min(xpCounter + Swift.max(1, target/30), target)
                if xpCounter >= target { t.invalidate() }
            }
            withAnimation(.spring(response: 0.5).delay(0.7))  { showStats = true }
            withAnimation(.spring(response: 0.5).delay(1.1))  { showAchs  = true }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    @ViewBuilder
    private func completionStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            Text(value).font(.subheadline.weight(.bold))
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(12)
        .background(Color(.systemBackground)).cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

// MARK: - Prep Data

struct BreathStepInfo: Identifiable {
    let id = UUID()
    let phase: String
    let duration: String
    let desc: String
    let color: Color
}

struct ExercisePrep {
    let rhythm: String
    let level: String
    let setup: [String]
    let breathSteps: [BreathStepInfo]
    let tips: [String]

    static func `for`(_ type: BreathingExercise.ExerciseType) -> ExercisePrep {
        switch type {
        case .diaphragmatic:
            return ExercisePrep(
                rhythm: "4–6 sn", level: "Başlangıç",
                setup: [
                    "Sırtın dik, omuzların rahat olacak şekilde otur veya uzan.",
                    "Bir elini göğsüne, diğerini karnına koy.",
                    "Gözlerini kapat ve omuzlarını gevşet.",
                    "Egzersiz boyunca sadece karnındaki el hareket etmeli."
                ],
                breathSteps: [
                    BreathStepInfo(phase: "Nefes Al",  duration: "4 sn", desc: "Burnundan yavaşça nefes al. Karnın şişmeli, göğsün sabit kalmalı.",        color: Color("AppPrimary")),
                    BreathStepInfo(phase: "Nefes Ver", duration: "6 sn", desc: "Ağzından ya da burnundan yavaşça ver. Karnını içeri çek, tüm hava çıksın.", color: Color("AppSuccess")),
                ],
                tips: [
                    "Başlangıçta zorlanmak normaldir, yavaş yavaş alışırsın.",
                    "Günde 2 kez, yemekten önce yapmak en etkili sonucu verir.",
                    "Koku alıyormuşsun gibi nefes almayı dene."
                ]
            )

        case .fourSevenEight:
            return ExercisePrep(
                rhythm: "4–7–8 sn", level: "Orta",
                setup: [
                    "Sırtını dik tut, rahat bir pozisyonda otur.",
                    "Dilin ucunu üst diş etine, ön dişlerin hemen arkasına değdir.",
                    "Bu dil pozisyonunu egzersiz boyunca koru.",
                    "Ağzın hafifçe açık kalacak, dil yerinde duracak."
                ],
                breathSteps: [
                    BreathStepInfo(phase: "Nefes Al",  duration: "4 sn", desc: "Burnundan sessizce nefes al, akciğerlerini tamamen doldur.",           color: Color("AppPrimary")),
                    BreathStepInfo(phase: "Tut",       duration: "7 sn", desc: "Nefesini rahatça tut. Zorlanma, sadece bekle.",                       color: Color("AppWarning")),
                    BreathStepInfo(phase: "Nefes Ver", duration: "8 sn", desc: "Ağzından \"fışşş\" sesiyle ver. Tüm havayı boşalt, rahatla.",         color: Color("AppSuccess")),
                ],
                tips: [
                    "Başlangıçta 2 döngü yeterli, zamanla 4'e kadar artır.",
                    "Uyku öncesi, stres anında çok etkilidir.",
                    "\"Fışşş\" sesi tam nefesi verdiğinin göstergesidir."
                ]
            )

        case .pursedLip:
            return ExercisePrep(
                rhythm: "2–4 sn", level: "KOAH için",
                setup: [
                    "Omuzlarını ve boyun kaslarını tamamen gevşet.",
                    "Ağzını kapalı tut, nefes almak için burnunu kullan.",
                    "Dudaklarını öpücük verecekmiş gibi büz.",
                    "Oturur pozisyonda ya da ayakta yapabilirsin."
                ],
                breathSteps: [
                    BreathStepInfo(phase: "Burundan Al",  duration: "2 sn", desc: "Burnundan yavaşça nefes al. Omuzların hareket etmemeli.",              color: Color("AppPrimary")),
                    BreathStepInfo(phase: "Büzük Dudak",  duration: "4 sn", desc: "Dudaklarını büz ve yavaş, kontrollü şekilde ver. Zorlamadan, akış.",  color: Color("AppWarning")),
                ],
                tips: [
                    "Nefes verme süresi, alma süresinin 2 katı olmalı.",
                    "Yürürken veya merdiven çıkarken de uygulanabilir.",
                    "Nefes darlığı hissedince anında kullanabilirsin."
                ]
            )

        case .boxBreathing:
            return ExercisePrep(
                rhythm: "4–4–4–4 sn", level: "Orta",
                setup: [
                    "Sırtın dik, ayaklarını yere bas.",
                    "Ekranına bak — animasyonun köşesinden köşesine geçişini takip et.",
                    "Her kenar bir faz: al, tut, ver, tut.",
                    "Omuzlarını gevşet, çeneni bırak."
                ],
                breathSteps: [
                    BreathStepInfo(phase: "Nefes Al",      duration: "4 sn", desc: "Burnundan derin nefes al, akciğerleri doldur.",             color: Color("AppPrimary")),
                    BreathStepInfo(phase: "Tut",           duration: "4 sn", desc: "Nefesini tut, rahat bekle.",                                color: Color("AppSuccess")),
                    BreathStepInfo(phase: "Nefes Ver",     duration: "4 sn", desc: "Ağzından yavaşça ver, tümünü boşalt.",                      color: Color("AppWarning")),
                    BreathStepInfo(phase: "Tekrar Tut",    duration: "4 sn", desc: "Boş akciğerle bekle, döngüye hazırlan.",                    color: Color("AppDanger")),
                ],
                tips: [
                    "Konsantrasyon gerektiren işler öncesi idealdir.",
                    "Navy SEAL'ların stres yönetimi tekniğidir.",
                    "4 döngü = yaklaşık 1 dakika."
                ]
            )

        case .controlledCough:
            return ExercisePrep(
                rhythm: "Adım adım", level: "Terapötik",
                setup: [
                    "Ayakta ya da sandalyede otur, öne hafifçe eğil.",
                    "Ellerini karnının üzerinde kavuştur.",
                    "Hızlı ve güçlü öksürmekten kaçın.",
                    "Ağrı veya baş dönmesinde dur ve dinlen."
                ],
                breathSteps: [
                    BreathStepInfo(phase: "Derin Nefes",     duration: "3 sn", desc: "Burnundan derin nefes al, 2–3 saniye tut.",                              color: Color("AppPrimary")),
                    BreathStepInfo(phase: "Diyafram Baskısı", duration: "2 sn", desc: "Ağzını kapat. Karın kaslarınla içe doğru bas.",                         color: Color("AppWarning")),
                    BreathStepInfo(phase: "Kısa Öksürük",    duration: "2 sn", desc: "Ağzını aç, 2 kısa güçlü öksürük yap. \"Huf-Huf\" gibi.",               color: Color("AppDanger")),
                    BreathStepInfo(phase: "Toparlan",         duration: "3 sn", desc: "Burnundan yavaşça nefes al. Omuzlarını bırak, sakinleş.",               color: Color("AppSuccess")),
                ],
                tips: [
                    "Mukusu temizlemek için günde 2–3 kez yapılabilir.",
                    "Gerekirse döngüyü 3–5 kez tekrarla.",
                    "Kronik bronşit ve KOAH hastalarına önerilir."
                ]
            )
        }
    }
}
