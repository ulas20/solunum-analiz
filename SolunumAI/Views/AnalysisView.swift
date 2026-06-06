import SwiftUI
import UniformTypeIdentifiers

// MARK: - Analysis View (3-step wizard)

struct AnalysisView: View {
    @StateObject private var recorder  = AudioRecorderService()
    @StateObject private var api       = APIService.shared
    @EnvironmentObject  private var coreData: CoreDataService

    @State private var currentStep: Int = 0
    @State private var request = AnalysisRequest()
    @State private var isAnalyzing    = false
    @State private var analysisResult: AnalysisResponse?
    @State private var errorMessage: String?
    @State private var showFilePicker  = false
    @State private var showError       = false
    @State private var lastSaved: SavedAnalysis?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StepIndicator(currentStep: currentStep)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                TabView(selection: $currentStep) {
                    Step1RecordingView(
                        recorder: recorder,
                        showFilePicker: $showFilePicker,
                        onNext: { currentStep = 1 }
                    )
                    .tag(0)

                    Step2SymptomsView(request: $request, onNext: { runAnalysis() }, onBack: { currentStep = 0 })
                        .tag(1)

                    Step3ResultsView(
                        isAnalyzing: isAnalyzing,
                        result: analysisResult,
                        savedAnalysis: lastSaved,
                        onRetry: { resetWizard() },
                        onSave: { saveResult() }
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
            .background(Color("AppBackground"))
            .navigationTitle("Analiz")
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.audio, UTType("public.mp3")!, .wav, UTType("com.apple.m4a-audio")!], allowsMultipleSelection: false) { result in
                if case .success(let urls) = result, let url = urls.first {
                    let accessed = url.startAccessingSecurityScopedResource()
                    recorder.importAudioFile(from: url)
                    if accessed { url.stopAccessingSecurityScopedResource() }
                }
            }
            .alert("Hata", isPresented: $showError, actions: {
                Button("Tamam") {}
                Button("Yeniden Dene") { runAnalysis() }
            }, message: {
                Text(errorMessage ?? "Bilinmeyen hata")
            })
        }
    }

    // MARK: - Actions

    private func runAnalysis() {
        guard let audioURL = recorder.trimmedAudioURL() ?? recorder.recordedFileURL else {
            errorMessage = "Lütfen önce ses kaydı yapın."
            showError = true
            return
        }
        recorder.stopPlayback()
        currentStep = 2
        isAnalyzing = true
        analysisResult = nil
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.analyze(audioURL: audioURL, request: request)
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                }
            } catch let err as APIError {
                await MainActor.run {
                    errorMessage = err.errorDescription
                    isAnalyzing = false
                    showError = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    showError = true
                }
            }
        }
    }

    private func saveResult() {
        guard let result = analysisResult else { return }
        lastSaved = coreData.saveAnalysis(response: result, request: request)
    }

    private func resetWizard() {
        recorder.reset()
        currentStep = 0
        analysisResult = nil
        isAnalyzing = false
        errorMessage = nil
        lastSaved = nil
        request = AnalysisRequest()
    }
}

// MARK: - Step Indicator

private struct StepIndicator: View {
    let currentStep: Int
    private let steps = ["Kayıt", "Belirtiler", "Sonuç"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { i in
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(i <= currentStep ? Color("AppPrimary") : Color(.systemGray4))
                                .frame(width: 28, height: 28)
                            if i < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(i + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(i <= currentStep ? .white : .secondary)
                            }
                        }
                        Text(steps[i])
                            .font(.caption2)
                            .foregroundColor(i <= currentStep ? Color("AppPrimary") : .secondary)
                    }

                    if i < steps.count - 1 {
                        Rectangle()
                            .fill(i < currentStep ? Color("AppPrimary") : Color(.systemGray4))
                            .frame(height: 2)
                            .padding(.bottom, 18)
                    }
                }
            }
        }
    }
}

// MARK: - Step 1: Recording

private struct Step1RecordingView: View {
    @ObservedObject var recorder: AudioRecorderService
    @Binding var showFilePicker: Bool
    let onNext: () -> Void

    @State private var showImportMenu = false

    private var isRecording: Bool {
        if case .recording = recorder.state { return true }
        return false
    }

    private var hasStopped: Bool {
        if case .stopped = recorder.state { return true }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Instruction card
                VStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Color("AppPrimary"))
                    Text("Sessiz bir odada, telefonu 20-30 cm yaklaştırın ve 3-5 saniye öksürün.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color("AppPrimary").opacity(0.08))
                .cornerRadius(12)

                // Waveform
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 80)

                    if isRecording {
                        AudioWaveformView(
                            samples: recorder.waveformSamples,
                            isRecording: true
                        )
                        .frame(height: 60)
                        .padding(.horizontal, 12)
                    } else {
                        IdleWaveformView()
                            .frame(height: 60)
                            .padding(.horizontal, 12)
                    }
                }

                // Mic button + level ring
                ZStack {
                    AudioLevelRingView(level: recorder.audioLevel)
                        .frame(width: 110, height: 110)

                    Button {
                        if isRecording {
                            recorder.stopRecording()
                        } else {
                            recorder.startRecording()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isRecording ? Color("AppDanger") : Color("AppPrimary"))
                                .frame(width: 80, height: 80)
                                .shadow(color: (isRecording ? Color("AppDanger") : Color("AppPrimary")).opacity(0.4), radius: 10)

                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(isRecording ? 1.06 : 1.0)
                    .animation(isRecording ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: isRecording)
                }

                // Timer + quality
                VStack(spacing: 6) {
                    Text(String(format: "%02d:%02d", Int(recorder.duration) / 60, Int(recorder.duration) % 60))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(isRecording ? Color("AppDanger") : .primary)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(recorder.isGoodQuality ? Color("AppSuccess") : Color(.systemGray3))
                            .frame(width: 8, height: 8)
                        Text(recorder.qualityLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("Min: 2 sn — Maks: 10 sn")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Error display
                if case .error(let msg) = recorder.state {
                    Label(msg, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundColor(Color("AppDanger"))
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(Color("AppDanger").opacity(0.1))
                        .cornerRadius(10)
                }

                // Playback + Trim (kayıt bittikten sonra)
                if hasStopped {
                    PlaybackTrimView(recorder: recorder)
                }

                // Action buttons
                VStack(spacing: 12) {
                    if hasStopped {
                        Button {
                            recorder.reset()
                        } label: {
                            Label("Yeniden Kaydet", systemImage: "arrow.counterclockwise")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color("AppPrimary"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AppPrimary").opacity(0.1))
                                .cornerRadius(12)
                        }

                        Button(action: onNext) {
                            Label("Devam Et", systemImage: "arrow.right")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AppPrimary"))
                                .cornerRadius(12)
                        }
                    }

                    Button { showFilePicker = true } label: {
                        Label("Dosyadan Yükle", systemImage: "folder.badge.plus")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Step 2: Symptoms

private struct Step2SymptomsView: View {
    @Binding var request: AnalysisRequest
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Personal info
                GroupBox(label: Label("Kişisel Bilgiler", systemImage: "person.fill")) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Yaş")
                            Spacer()
                            Stepper("\(request.yas)", value: $request.yas, in: 0...120)
                        }

                        Divider()

                        HStack {
                            Text("Cinsiyet")
                            Spacer()
                            Picker("", selection: $request.cinsiyet) {
                                Text("Kadın").tag(0)
                                Text("Erkek").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                    }
                    .padding(.top, 4)
                }

                // Symptoms
                GroupBox(label: Label("Belirtiler", systemImage: "list.bullet.clipboard.fill")) {
                    VStack(spacing: 0) {
                        SymptomRow(icon: "wind",                        label: "Hırıltılı Solunum Geçmişi", value: $request.wheezeGecmis)
                        SymptomRow(icon: "drop.fill",                   label: "Balgamlı Öksürük",          value: $request.balgam)
                        SymptomRow(icon: "thermometer.sun.fill",        label: "Ateş",                      value: $request.ates)
                        SymptomRow(icon: "person.2.fill",               label: "Ailede Astım",              value: $request.aileAstim)
                        SymptomRow(icon: "exclamationmark.shield.fill", label: "Tüberküloz Teması",         value: $request.tbTemas)
                        SymptomRow(icon: "smoke.fill",                  label: "Sigara Kullanımı",          value: $request.sigara)
                    }
                }

                // Pack years (only if smoker)
                if request.sigara {
                    GroupBox(label: Label("Sigara Geçmişi", systemImage: "smoke.fill")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Paket-Yıl")
                                Spacer()
                                Text("\(request.packYears)")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(Color("AppPrimary"))
                            }
                            Slider(value: Binding(
                                get: { Double(request.packYears) },
                                set: { request.packYears = Int($0) }
                            ), in: 0...100, step: 1)
                            .accentColor(Color("AppPrimary"))
                            Text("Günlük paket sayısı × yıl. (Örn: 1 paket/gün × 10 yıl = 10)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Nav buttons
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        Label("Geri", systemImage: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color("AppPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AppPrimary").opacity(0.1))
                            .cornerRadius(12)
                    }

                    Button(action: onNext) {
                        Label("Analiz Et", systemImage: "waveform.badge.magnifyingglass")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AppPrimary"))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
}

private struct SymptomRow: View {
    let icon: String
    let label: String
    @Binding var value: Bool

    var body: some View {
        Toggle(isOn: $value) {
            Label(label, systemImage: icon)
                .font(.subheadline)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        Divider()
    }
}

// MARK: - Step 3: Results

private struct Step3ResultsView: View {
    let isAnalyzing: Bool
    let result: AnalysisResponse?
    let savedAnalysis: SavedAnalysis?
    let onRetry: () -> Void
    let onSave: () -> Void

    @State private var isSaved = false

    var body: some View {
        ScrollView {
            if isAnalyzing {
                LoadingView()
                    .padding(.top, 60)
            } else if let result {
                ResultsCard(result: result, isSaved: isSaved, onSave: {
                    onSave()
                    isSaved = true
                }, onRetry: onRetry)
            }
        }
    }
}

private struct LoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color("AppPrimary").opacity(0.15), lineWidth: 6)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color("AppPrimary"), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }

                Image(systemName: "lungs.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color("AppPrimary"))
            }

            VStack(spacing: 8) {
                Text("Analiz Ediliyor...")
                    .font(.title3.weight(.semibold))
                Text("Ses kaydınız yapay zeka modelleri tarafından işleniyor.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}

private struct ResultsCard: View {
    let result: AnalysisResponse
    let isSaved: Bool
    let onSave: () -> Void
    let onRetry: () -> Void

    var riskColor: Color {
        switch result.riskLevel {
        case .low:      return Color("AppSuccess")
        case .moderate: return Color("AppWarning")
        case .high:     return Color("AppDanger")
        }
    }

    var body: some View {
        VStack(spacing: 20) {

            // Gauge
            RiskGaugeView(value: result.pFinal, size: 180)
                .padding(.top, 8)

            // Diagnosis badge
            HStack {
                Image(systemName: "stethoscope")
                Text(result.airsIsim)
                    .font(.headline)
            }
            .foregroundColor(riskColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(riskColor.opacity(0.12))
            .cornerRadius(20)

            // Model breakdown
            VStack(alignment: .leading, spacing: 14) {
                Text("Model Detayları")
                    .font(.headline)
                ScoreBarView(label: "Gribal Rahatsızlık (P1)",  value: result.p1, color: Color("AppWarning"))
                ScoreBarView(label: "Astım / KOAH (P2)",        value: result.p2, color: Color("AppDanger"))
                ScoreBarView(label: "Birleşik Skor (P_Final)",  value: result.pFinal, color: riskColor)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 6)

            // Assessment
            VStack(alignment: .leading, spacing: 10) {
                Label(result.genel, systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundColor(riskColor)
                Text(result.altKarar)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 6)

            // Recommendation
            VStack(alignment: .leading, spacing: 10) {
                Label("Öneri", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundColor(Color("AppPrimary"))
                Text(result.oneri)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color("AppPrimary").opacity(0.07))
            .cornerRadius(14)

            // Action buttons
            VStack(spacing: 12) {
                Button(action: onSave) {
                    Label(isSaved ? "Kaydedildi ✓" : "Geçmişe Kaydet", systemImage: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSaved ? Color("AppSuccess") : Color("AppPrimary"))
                        .cornerRadius(12)
                }
                .disabled(isSaved)

                Button(action: onRetry) {
                    Label("Yeni Analiz", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color("AppPrimary"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AppPrimary").opacity(0.1))
                        .cornerRadius(12)
                }
            }

            // Disclaimer
            Text("⚠️ Bu uygulama tıbbi tanı koyamaz. Sonuçlar yalnızca bilgilendirme amaçlıdır. Kesin tanı için doktorunuza başvurun.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Playback + Trim

private struct PlaybackTrimView: View {
    @ObservedObject var recorder: AudioRecorderService

    private var totalDuration: TimeInterval { recorder.recordedDuration }
    private var trimDuration: TimeInterval { recorder.trimEnd - recorder.trimStart }

    var body: some View {
        VStack(spacing: 14) {
            // Playback controls
            HStack(spacing: 20) {
                Button {
                    recorder.seek(to: recorder.trimStart)
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.title3)
                        .foregroundColor(Color("AppPrimary"))
                }

                Button { recorder.togglePlayback() } label: {
                    ZStack {
                        Circle()
                            .fill(Color("AppPrimary"))
                            .frame(width: 52, height: 52)
                        Image(systemName: recorder.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(formatTime(recorder.playbackTime))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                    Text("/ \(formatTime(totalDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(formatTime(trimDuration))")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(trimDuration > recorder.maxDuration ? Color("AppDanger") : Color("AppSuccess"))
                    Text("seçili")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Playback progress bar (tappable)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    // Selected trim region
                    let startX = CGFloat(recorder.trimStart / max(totalDuration, 0.001)) * geo.size.width
                    let endX   = CGFloat(recorder.trimEnd   / max(totalDuration, 0.001)) * geo.size.width
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("AppPrimary").opacity(0.3))
                        .frame(width: endX - startX, height: 6)
                        .offset(x: startX)

                    // Playback position
                    let posX = CGFloat(recorder.playbackTime / max(totalDuration, 0.001)) * geo.size.width
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("AppPrimary"))
                        .frame(width: max(posX, 2), height: 6)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { val in
                    let ratio = val.location.x / geo.size.width
                    let t = Swift.max(0, Swift.min(totalDuration, ratio * totalDuration))
                    recorder.seek(to: t)
                })
            }
            .frame(height: 20)

            // Trim sliders
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "scissors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Başlangıç: \(formatTime(recorder.trimStart))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Bitiş: \(formatTime(recorder.trimEnd))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Start trim slider
                HStack(spacing: 8) {
                    Text("▸")
                        .font(.caption)
                        .foregroundColor(Color("AppSuccess"))
                    Slider(
                        value: Binding(
                            get: { recorder.trimStart },
                            set: { val in
                                let clamped = Swift.min(val, recorder.trimEnd - 2.0)
                                recorder.trimStart = max(0, clamped)
                                if recorder.playbackTime < recorder.trimStart {
                                    recorder.seek(to: recorder.trimStart)
                                }
                            }
                        ),
                        in: 0...(max(totalDuration - 2, 0))
                    )
                    .accentColor(Color("AppSuccess"))
                }

                // End trim slider
                HStack(spacing: 8) {
                    Text("◾")
                        .font(.caption)
                        .foregroundColor(Color("AppDanger"))
                    Slider(
                        value: Binding(
                            get: { recorder.trimEnd },
                            set: { val in
                                let clamped = max(val, recorder.trimStart + 2.0)
                                recorder.trimEnd = Swift.min(clamped, Swift.min(recorder.maxDuration, totalDuration))
                            }
                        ),
                        in: 2...Swift.max(Swift.min(totalDuration, recorder.maxDuration), 2)
                    )
                    .accentColor(Color("AppDanger"))
                }
            }

            if totalDuration > recorder.maxDuration {
                Label("Kayıt \(formatTime(recorder.maxDuration))'den uzun — sadece seçilen bölüm gönderilecek.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(Color("AppWarning"))
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 6)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let secs = Int(t)
        let frac = Int((t - Double(secs)) * 10)
        return String(format: "%d.%ds", secs, frac)
    }
}

#Preview {
    AnalysisView()
        .environmentObject(CoreDataService.shared)
}
