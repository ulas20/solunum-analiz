import SwiftUI

struct HomeView: View {
    @EnvironmentObject var coreData: CoreDataService
    @StateObject private var exerciseProgress = ExerciseProgressService.shared
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Greeting
                    GreetingHeader()
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // Today's activity summary
                    TodaySummaryCard(coreData: coreData, exerciseProgress: exerciseProgress)
                        .padding(.horizontal)

                    // Quick actions
                    QuickActionsRow(selectedTab: $selectedTab)
                        .padding(.horizontal)

                    // Last analysis teaser
                    if let last = coreData.fetchAll().first {
                        LastAnalysisCard(analysis: last)
                            .padding(.horizontal)
                    }

                    // Exercise level strip
                    ExerciseLevelStrip(progress: exerciseProgress, selectedTab: $selectedTab)
                        .padding(.horizontal)

                    // Health tips
                    HealthTipsSection()
                }
                .padding(.bottom, 40)
            }
            .background(Color("AppBackground"))
            .navigationTitle("SolunumAI")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Greeting Header

private struct GreetingHeader: View {
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12  { return "Günaydın 🌤" }
        if h < 18  { return "İyi Günler ☀️" }
        return "İyi Akşamlar 🌙"
    }

    private var subtext: String {
        "Solunum sağlığını takip etmeye devam et."
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                Text(subtext)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color("AppPrimary").opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "lungs.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color("AppPrimary"))
            }
        }
    }
}

// MARK: - Today's Summary Card

private struct TodaySummaryCard: View {
    let coreData: CoreDataService
    let exerciseProgress: ExerciseProgressService

    private var analysedToday: Bool {
        guard let d = coreData.lastAnalysisDate else { return false }
        return Calendar.current.isDateInToday(d)
    }

    private var exercisedToday: Bool {
        for stat in exerciseProgress.exerciseStats.values {
            if let d = stat.lastSessionDate, Calendar.current.isDateInToday(d) { return true }
        }
        return false
    }
 
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bugün")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: 12) {
                TodayPillItem(
                    icon: "waveform.badge.mic",
                    label: "Analiz",
                    done: analysedToday,
                    doneText: "Yapıldı",
                    todoText: "Yapılmadı"
                )
                TodayPillItem(
                    icon: "figure.mind.and.body",
                    label: "Egzersiz",
                    done: exercisedToday,
                    doneText: "Tamamlandı",
                    todoText: "Yapılmadı"
                )
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                        Text("\(coreData.streakDays)")
                            .font(.title3.weight(.bold))
                    }
                    Text("Gün serisi")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8)
    }
}

private struct TodayPillItem: View {
    let icon: String
    let label: String
    let done: Bool
    let doneText: String
    let todoText: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 16))
                .foregroundColor(done ? Color("AppSuccess") : .secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(done ? doneText : todoText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(done ? Color("AppSuccess") : .primary)
            }
        }
    }
}

// MARK: - Quick Actions Row

private struct QuickActionsRow: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 12) {
            QuickActionCard(
                icon: "waveform.badge.mic",
                title: "Analiz Yap",
                subtitle: "Öksürüğünü kaydet",
                gradient: [Color("AppPrimary"), Color("AppPrimary").opacity(0.75)],
                action: { withAnimation { selectedTab = 1 } }
            )
            QuickActionCard(
                icon: "figure.mind.and.body",
                title: "Egzersiz",
                subtitle: "Nefes çalışması",
                gradient: [Color("AppSuccess"), Color("AppSuccess").opacity(0.75)],
                action: { withAnimation { selectedTab = 3 } }
            )
        }
    }
}

private struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.82))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 130)
            .background(
                LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(18)
            .shadow(color: gradient[0].opacity(0.35), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Last Analysis Card

private struct LastAnalysisCard: View {
    let analysis: SavedAnalysis

    private var riskColor: Color {
        let g = analysis.genel.lowercased()
        if g.contains("yüksek") || g.contains("ciddi") { return Color("AppDanger") }
        if g.contains("orta")  || g.contains("dikkat")  { return Color("AppWarning") }
        return Color("AppSuccess")
    }

    private var riskIcon: String {
        let g = analysis.genel.lowercased()
        if g.contains("yüksek") || g.contains("ciddi") { return "exclamationmark.triangle.fill" }
        if g.contains("orta")  || g.contains("dikkat")  { return "exclamationmark.circle.fill" }
        return "checkmark.shield.fill"
    }

    private var dateStr: String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "tr_TR")
        return f.localizedString(for: analysis.date, relativeTo: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Son Analiz")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
                Text(dateStr)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(riskColor.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: riskIcon)
                        .font(.system(size: 22))
                        .foregroundColor(riskColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(analysis.genel)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(riskColor)
                    Text(analysis.altKarar)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.0f%%", analysis.pFinal * 100))
                        .font(.title3.weight(.bold))
                        .foregroundColor(riskColor)
                    Text("Risk skoru")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Risk bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    Capsule()
                        .fill(riskColor)
                        .frame(width: geo.size.width * min(analysis.pFinal, 1.0), height: 6)
                }
            }
            .frame(height: 6)

            Text(analysis.oneri)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8)
    }
}

// MARK: - Exercise Level Strip

private struct ExerciseLevelStrip: View {
    @ObservedObject var progress: ExerciseProgressService
    @Binding var selectedTab: Int

    var body: some View {
        Button { withAnimation { selectedTab = 3 } } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(progress.currentLevel.color).opacity(0.14))
                        .frame(width: 48, height: 48)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(progress.currentLevel.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(progress.currentLevel.name)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(Color(progress.currentLevel.color))
                        Text("• \(progress.totalXP) XP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                            Capsule()
                                .fill(Color(progress.currentLevel.color).opacity(0.8))
                                .frame(width: geo.size.width * progress.xpProgress)
                        }
                    }
                    .frame(height: 5)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("\(progress.dailyStreak) gün")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.orange)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Health Tips Section

private struct HealthTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sağlık Rehberi")
                .font(.title3.weight(.bold))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HealthTip.all) { tip in
                        HealthTipHScrollCard(tip: tip)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
        .environmentObject(CoreDataService.shared)
}
