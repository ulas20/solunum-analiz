import SwiftUI

struct ExercisesView: View {
    @StateObject private var progress = ExerciseProgressService.shared
    @State private var selectedExercise: BreathingExercise?
    @State private var showAchievements = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Level & Streak Header ──────────────────────────
                    LevelHeaderView(progress: progress)
                        .padding(.horizontal)
                        .padding(.top, 4)

                    // ── Stats Row ─────────────────────────────────────
                    HStack(spacing: 12) {
                        MiniStatView(icon: "flame.fill",         color: .orange,              label: "Seri",    value: "\(progress.dailyStreak) gün")
                        MiniStatView(icon: "checkmark.circle.fill", color: Color("AppSuccess"), label: "Seans", value: "\(progress.totalSessions)")
                        MiniStatView(icon: "clock.fill",         color: Color("AppPrimary"),   label: "Dakika",  value: String(format: "%.0f", progress.totalMinutes))
                        MiniStatView(icon: "medal.fill",         color: .yellow,               label: "Rozet",   value: "\(progress.unlockedCount)/\(Achievement.all.count)")
                    }
                    .padding(.horizontal)

                    // ── Achievements strip ─────────────────────────────
                    Button { showAchievements = true } label: {
                        HStack(spacing: 12) {
                            ForEach(progress.achievements.filter { $0.isUnlocked }.prefix(5)) { ach in
                                Image(systemName: ach.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.yellow)
                                    .frame(width: 40, height: 40)
                                    .background(Color.yellow.opacity(0.12))
                                    .clipShape(Circle())
                            }

                            let locked = Achievement.all.count - progress.unlockedCount
                            if locked > 0 {
                                Text("+\(locked) kilitli")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(14)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // ── Exercise Cards ─────────────────────────────────
                    Text("Egzersizler")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    ForEach(BreathingExercise.all) { exercise in
                        ExerciseCardView(
                            exercise: exercise,
                            stats: progress.exerciseStats[exercise.id.uuidString],
                            isCompleted: progress.completedExerciseIds.contains(exercise.id.uuidString)
                        ) {
                            selectedExercise = exercise
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color("AppBackground"))
            .navigationTitle("Egzersizler")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAchievements = true } label: {
                        Image(systemName: "medal.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseSessionView(exercise: exercise, progress: progress)
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView(achievements: progress.achievements)
            }
        }
    }
}

// MARK: - Level Header

private struct LevelHeaderView: View {
    @ObservedObject var progress: ExerciseProgressService

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(progress.currentLevel.name)
                            .font(.title2.weight(.bold))
                            .foregroundColor(Color(progress.currentLevel.color))
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(Color(progress.currentLevel.color).opacity(0.6))
                    }
                    Text("\(progress.totalXP) XP  •  Sonraki: \(progress.xpToNextLevel) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                // XP orb
                ZStack {
                    Circle()
                        .fill(Color(progress.currentLevel.color).opacity(0.12))
                        .frame(width: 60, height: 60)
                    VStack(spacing: 1) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(progress.currentLevel.color))
                        Text("\(progress.totalXP)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(progress.currentLevel.color))
                    }
                }
            }

            // XP bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(progress.currentLevel.color).opacity(0.7), Color(progress.currentLevel.color)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * progress.xpProgress)
                        .animation(.spring(response: 0.6), value: progress.xpProgress)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8)
    }
}

// MARK: - Mini Stat

private struct MiniStatView: View {
    let icon: String
    let color: Color
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(.subheadline.weight(.bold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4)
    }
}

// MARK: - Exercise Card

struct ExerciseCardView: View {
    let exercise: BreathingExercise
    let stats: ExerciseStats?
    let isCompleted: Bool
    let onStart: () -> Void

    private var accentColor: Color { Color(exercise.color) }
    private var durationStr: String {
        let m = exercise.duration / 60
        let s = exercise.duration % 60
        return s == 0 ? "\(m) dk" : "\(m) dk \(s) sn"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(accentColor)

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color("AppSuccess"))
                            .offset(x: 18, y: -18)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.headline)
                    Text(exercise.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Stats row
                    if let s = stats, s.totalSessions > 0 {
                        HStack(spacing: 8) {
                            Label("\(s.totalSessions) seans", systemImage: "checkmark")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            if s.currentStreak > 1 {
                                Label("\(s.currentStreak) seri", systemImage: "flame.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(durationStr)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(accentColor)

                    Button(action: onStart) {
                        Text("Başla")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(accentColor)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(16)

            // Benefits (always visible)
            Text(exercise.benefits)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8)
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

// MARK: - Achievements Sheet

struct AchievementsView: View {
    let achievements: [Achievement]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(achievements) { ach in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(ach.isUnlocked ? Color.yellow.opacity(0.15) : Color(.systemGray5))
                                    .frame(width: 52, height: 52)
                                Image(systemName: ach.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(ach.isUnlocked ? .yellow : .secondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(ach.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(ach.isUnlocked ? .primary : .secondary)
                                    if ach.isUnlocked {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(Color("AppSuccess"))
                                    }
                                }
                                Text(ach.desc)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let date = ach.unlockedDate {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Text("+\(ach.xpReward) XP")
                                .font(.caption.weight(.bold))
                                .foregroundColor(ach.isUnlocked ? .yellow : .secondary)
                        }
                        .padding(14)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.04), radius: 4)
                        .opacity(ach.isUnlocked ? 1.0 : 0.55)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color("AppBackground"))
            .navigationTitle("Rozetler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ExercisesView()
}
