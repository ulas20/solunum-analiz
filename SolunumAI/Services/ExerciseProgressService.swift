import Foundation
import Combine

// MARK: - Models

struct ExerciseStats: Codable {
    var totalSessions: Int = 0
    var totalMinutes: Double = 0
    var lastSessionDate: Date? = nil
    var currentStreak: Int = 0
    var bestStreak: Int = 0
}

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let desc: String
    let icon: String
    let xpReward: Int
    var isUnlocked: Bool = false
    var unlockedDate: Date? = nil

    static let all: [Achievement] = [
        Achievement(id: "first",       title: "İlk Adım",             desc: "İlk egzersizini tamamladın",         icon: "star.fill",             xpReward: 50),
        Achievement(id: "streak3",     title: "3 Günlük Seri",        desc: "3 gün üst üste egzersiz yaptın",     icon: "flame.fill",            xpReward: 75),
        Achievement(id: "streak7",     title: "Haftanın Şampiyonu",   desc: "7 gün üst üste egzersiz yaptın",     icon: "trophy.fill",           xpReward: 150),
        Achievement(id: "streak30",    title: "Nefes Ustası",         desc: "30 gün üst üste egzersiz yaptın",    icon: "crown.fill",            xpReward: 500),
        Achievement(id: "sessions10",  title: "Düzenli Pratik",       desc: "Toplam 10 seans tamamladın",         icon: "checkmark.seal.fill",   xpReward: 100),
        Achievement(id: "sessions30",  title: "Kararlı Sporcu",       desc: "Toplam 30 seans tamamladın",         icon: "figure.mind.and.body",  xpReward: 200),
        Achievement(id: "minutes60",   title: "Bir Saat Nefes",       desc: "Toplam 60 dakika egzersiz yaptın",   icon: "lungs.fill",            xpReward: 120),
        Achievement(id: "allTypes",    title: "Tam Set",              desc: "Her egzersiz türünü bir kez yaptın", icon: "sparkles",              xpReward: 200),
    ]
}

// MARK: - Levels

struct ExerciseLevel {
    let name: String
    let minXP: Int
    let maxXP: Int
    let color: String

    static let levels: [ExerciseLevel] = [
        ExerciseLevel(name: "Başlangıç",   minXP: 0,    maxXP: 150,  color: "AppSuccess"),
        ExerciseLevel(name: "Orta",        minXP: 150,  maxXP: 400,  color: "AppPrimary"),
        ExerciseLevel(name: "İleri",       minXP: 400,  maxXP: 800,  color: "AppWarning"),
        ExerciseLevel(name: "Uzman",       minXP: 800,  maxXP: 1500, color: "AppDanger"),
        ExerciseLevel(name: "Usta",        minXP: 1500, maxXP: 9999, color: "AppPrimary"),
    ]

    static func current(for xp: Int) -> ExerciseLevel {
        levels.last(where: { xp >= $0.minXP }) ?? levels[0]
    }
}

// MARK: - Session Result

struct SessionResult {
    let xpEarned: Int
    let newAchievements: [Achievement]
    let newStreak: Int
    let totalSessions: Int
}

// MARK: - Service

final class ExerciseProgressService: ObservableObject {

    static let shared = ExerciseProgressService()

    @Published var totalXP: Int = 0
    @Published var dailyStreak: Int = 0
    @Published var totalSessions: Int = 0
    @Published var totalMinutes: Double = 0
    @Published var achievements: [Achievement] = Achievement.all
    @Published var exerciseStats: [String: ExerciseStats] = [:]
    @Published var completedExerciseIds: Set<String> = []

    private let defaults = UserDefaults.standard
    private var lastActiveDate: Date? {
        get { defaults.object(forKey: "lastActiveDate") as? Date }
        set { defaults.set(newValue, forKey: "lastActiveDate") }
    }

    private init() { load() }

    // MARK: - Level

    var currentLevel: ExerciseLevel { ExerciseLevel.current(for: totalXP) }

    var xpProgress: Double {
        let lvl = currentLevel
        let range = Double(lvl.maxXP - lvl.minXP)
        let progress = Double(totalXP - lvl.minXP)
        return range > 0 ? min(progress / range, 1.0) : 1.0
    }

    var xpToNextLevel: Int {
        max(0, currentLevel.maxXP - totalXP)
    }

    // MARK: - Complete Session

    @discardableResult
    func completeSession(exerciseId: String, exerciseTitle: String, durationMinutes: Double) -> SessionResult {
        var xpEarned = 0

        // Base XP: 10 per minute
        xpEarned += Int(durationMinutes * 10)

        // Bonus for completing full session
        xpEarned += 20

        // Update global stats
        totalXP += xpEarned
        totalSessions += 1
        totalMinutes += durationMinutes

        // Update per-exercise stats
        var stat = exerciseStats[exerciseId] ?? ExerciseStats()
        stat.totalSessions += 1
        stat.totalMinutes += durationMinutes

        // Streak logic
        let today = Calendar.current.startOfDay(for: Date())
        if let last = stat.lastSessionDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 0 {
                // Same day — no change
            } else if diff == 1 {
                stat.currentStreak += 1
            } else {
                stat.currentStreak = 1
            }
        } else {
            stat.currentStreak = 1
        }
        stat.bestStreak = max(stat.bestStreak, stat.currentStreak)
        stat.lastSessionDate = Date()
        exerciseStats[exerciseId] = stat

        // Global streak
        updateGlobalStreak()

        // Track which exercise types completed
        completedExerciseIds.insert(exerciseId)

        // Check achievements
        let newAchs = checkAchievements(exerciseId: exerciseId)
        for ach in newAchs {
            xpEarned += ach.xpReward
            totalXP += ach.xpReward
        }

        save()

        return SessionResult(
            xpEarned: xpEarned,
            newAchievements: newAchs,
            newStreak: stat.currentStreak,
            totalSessions: totalSessions
        )
    }

    private func updateGlobalStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastActiveDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 0 { /* same day */ }
            else if diff == 1 { dailyStreak += 1 }
            else { dailyStreak = 1 }
        } else {
            dailyStreak = 1
        }
        lastActiveDate = Date()
    }

    // MARK: - Achievements

    private func checkAchievements(exerciseId: String) -> [Achievement] {
        var newly: [Achievement] = []

        func unlock(_ id: String) {
            if let idx = achievements.firstIndex(where: { $0.id == id && !$0.isUnlocked }) {
                achievements[idx].isUnlocked = true
                achievements[idx].unlockedDate = Date()
                newly.append(achievements[idx])
            }
        }

        if totalSessions >= 1   { unlock("first") }
        if dailyStreak  >= 3   { unlock("streak3") }
        if dailyStreak  >= 7   { unlock("streak7") }
        if dailyStreak  >= 30  { unlock("streak30") }
        if totalSessions >= 10 { unlock("sessions10") }
        if totalSessions >= 30 { unlock("sessions30") }
        if totalMinutes  >= 60 { unlock("minutes60") }
        if completedExerciseIds.count >= BreathingExercise.all.count { unlock("allTypes") }

        return newly
    }

    var unlockedCount: Int { achievements.filter { $0.isUnlocked }.count }

    // MARK: - Persistence

    private func save() {
        defaults.set(totalXP, forKey: "ex_totalXP")
        defaults.set(dailyStreak, forKey: "ex_dailyStreak")
        defaults.set(totalSessions, forKey: "ex_totalSessions")
        defaults.set(totalMinutes, forKey: "ex_totalMinutes")

        if let data = try? JSONEncoder().encode(achievements) {
            defaults.set(data, forKey: "ex_achievements")
        }
        if let data = try? JSONEncoder().encode(exerciseStats) {
            defaults.set(data, forKey: "ex_stats")
        }
        if let data = try? JSONEncoder().encode(Array(completedExerciseIds)) {
            defaults.set(data, forKey: "ex_completedIds")
        }
    }

    private func load() {
        totalXP        = defaults.integer(forKey: "ex_totalXP")
        dailyStreak    = defaults.integer(forKey: "ex_dailyStreak")
        totalSessions  = defaults.integer(forKey: "ex_totalSessions")
        totalMinutes   = defaults.double(forKey: "ex_totalMinutes")

        if let data = defaults.data(forKey: "ex_achievements"),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Merge saved unlock state with master list (preserves new achievements added later)
            achievements = Achievement.all.map { master in
                decoded.first(where: { $0.id == master.id }) ?? master
            }
        }
        if let data = defaults.data(forKey: "ex_stats"),
           let decoded = try? JSONDecoder().decode([String: ExerciseStats].self, from: data) {
            exerciseStats = decoded
        }
        if let data = defaults.data(forKey: "ex_completedIds"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            completedExerciseIds = Set(decoded)
        }
    }

    func resetAll() {
        totalXP = 0; dailyStreak = 0; totalSessions = 0; totalMinutes = 0
        achievements = Achievement.all
        exerciseStats = [:]
        completedExerciseIds = []
        lastActiveDate = nil
        save()
    }
}
