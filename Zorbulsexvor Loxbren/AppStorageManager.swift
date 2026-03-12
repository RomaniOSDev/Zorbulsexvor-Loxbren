//
//  AppStorageManager.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Foundation
import Combine

final class AppStorageManager: ObservableObject {
    static let shared = AppStorageManager()

    struct Keys {
        static let starsPerLevel = "starsPerLevel"
        static let unlockedLevelIndex = "unlockedLevelIndex"
        static let totalPlayTime = "totalPlayTime"
        static let totalActivitiesPlayed = "totalActivitiesPlayed"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let currentStreakDays = "currentStreakDays"
        static let bestStreakDays = "bestStreakDays"
        static let lastPlayedDay = "lastPlayedDay"
        static let adaptivePerformanceByTrack = "adaptivePerformanceByTrack"
        static let completedDailyChallengeDays = "completedDailyChallengeDays"
    }

    static let resetNotification = Notification.Name("AppStorageManagerResetAll")

    @Published private(set) var starsPerLevel: [String: Int]
    @Published private(set) var unlockedLevelIndex: [String: Int]
    @Published private(set) var totalPlayTime: TimeInterval
    @Published private(set) var totalActivitiesPlayed: Int
    @Published private(set) var currentStreakDays: Int
    @Published private(set) var bestStreakDays: Int
    @Published private(set) var adaptivePerformanceByTrack: [String: Int]
    @Published private(set) var completedDailyChallengeDays: Set<String>
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding)
        }
    }

    private var lastPlayedDay: String

    private init() {
        let defaults = UserDefaults.standard
        starsPerLevel = defaults.dictionary(forKey: Keys.starsPerLevel) as? [String: Int] ?? [:]
        unlockedLevelIndex = defaults.dictionary(forKey: Keys.unlockedLevelIndex) as? [String: Int] ?? [:]
        totalPlayTime = defaults.double(forKey: Keys.totalPlayTime)
        totalActivitiesPlayed = defaults.integer(forKey: Keys.totalActivitiesPlayed)
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        currentStreakDays = defaults.integer(forKey: Keys.currentStreakDays)
        bestStreakDays = defaults.integer(forKey: Keys.bestStreakDays)
        lastPlayedDay = defaults.string(forKey: Keys.lastPlayedDay) ?? ""
        adaptivePerformanceByTrack = defaults.dictionary(forKey: Keys.adaptivePerformanceByTrack) as? [String: Int] ?? [:]
        let completed = defaults.array(forKey: Keys.completedDailyChallengeDays) as? [String] ?? []
        completedDailyChallengeDays = Set(completed)
    }

    // MARK: - Level and stars

    func stars(for levelID: String) -> Int {
        starsPerLevel[levelID] ?? 0
    }

    func updateStars(for levelID: String, newStars: Int) {
        let clamped = max(0, min(3, newStars))
        let current = starsPerLevel[levelID] ?? 0
        if clamped > current {
            starsPerLevel[levelID] = clamped
            UserDefaults.standard.set(starsPerLevel, forKey: Keys.starsPerLevel)
        }
    }

    func highestUnlockedLevelIndex(for trackID: String) -> Int {
        unlockedLevelIndex[trackID] ?? 0
    }

    func unlockNextLevelIfNeeded(for trackID: String, completedIndex: Int, maxIndex: Int) {
        let current = highestUnlockedLevelIndex(for: trackID)
        if completedIndex >= current, completedIndex < maxIndex {
            unlockedLevelIndex[trackID] = completedIndex + 1
            UserDefaults.standard.set(unlockedLevelIndex, forKey: Keys.unlockedLevelIndex)
        }
    }

    // MARK: - Stats

    func addPlaySession(duration: TimeInterval) {
        guard duration > 0 else { return }
        totalPlayTime += duration
        totalActivitiesPlayed += 1
        UserDefaults.standard.set(totalPlayTime, forKey: Keys.totalPlayTime)
        UserDefaults.standard.set(totalActivitiesPlayed, forKey: Keys.totalActivitiesPlayed)
        updateStreak(for: Date())
    }

    func recordOutcome(for trackID: String, didWin: Bool) {
        let current = adaptivePerformanceByTrack[trackID] ?? 0
        let updated: Int
        if didWin {
            updated = max(0, current) + 1
        } else {
            updated = min(0, current) - 1
        }
        adaptivePerformanceByTrack[trackID] = max(-5, min(5, updated))
        UserDefaults.standard.set(adaptivePerformanceByTrack, forKey: Keys.adaptivePerformanceByTrack)
    }

    func adaptiveModifier(for trackID: String) -> Int {
        let streak = adaptivePerformanceByTrack[trackID] ?? 0
        if streak <= -3 {
            return -1
        } else if streak >= 3 {
            return 1
        } else {
            return 0
        }
    }

    func levelGoals(for level: GameLevel) -> [LevelGoal] {
        let baseID = "\(level.activity.rawValue)_\(level.difficulty.rawValue)_\(level.index)"
        switch level.activity {
        case .pixelMatch:
            switch level.difficulty {
            case .easy:
                return [
                    LevelGoal(id: "\(baseID)_time", kind: .finishUnder(seconds: 45)),
                    LevelGoal(id: "\(baseID)_moves", kind: .maxMoves(20))
                ]
            case .normal:
                return [
                    LevelGoal(id: "\(baseID)_time", kind: .finishUnder(seconds: 40)),
                    LevelGoal(id: "\(baseID)_moves", kind: .maxMoves(26))
                ]
            case .hard:
                return [
                    LevelGoal(id: "\(baseID)_time", kind: .finishUnder(seconds: 32)),
                    LevelGoal(id: "\(baseID)_moves", kind: .maxMoves(34))
                ]
            }
        case .shapeSort:
            switch level.difficulty {
            case .easy:
                return [
                    LevelGoal(id: "\(baseID)_time", kind: .finishUnder(seconds: 42)),
                    LevelGoal(id: "\(baseID)_mistakes", kind: .noMistakes)
                ]
            case .normal:
                return [
                    LevelGoal(id: "\(baseID)_time", kind: .finishUnder(seconds: 35)),
                    LevelGoal(id: "\(baseID)_mistakes", kind: .noMistakes)
                ]
            case .hard:
                return [
                    LevelGoal(id: "\(baseID)_time", kind: .finishUnder(seconds: 30)),
                    LevelGoal(id: "\(baseID)_moves", kind: .maxMoves(16))
                ]
            }
        case .patternRecall:
            switch level.difficulty {
            case .easy:
                return [
                    LevelGoal(id: "\(baseID)_time", kind: .finishUnder(seconds: 35)),
                    LevelGoal(id: "\(baseID)_mistakes", kind: .noMistakes)
                ]
            case .normal:
                return [
                    LevelGoal(id: "\(baseID)_time", kind: .finishUnder(seconds: 32)),
                    LevelGoal(id: "\(baseID)_mistakes", kind: .noMistakes)
                ]
            case .hard:
                return [
                    LevelGoal(id: "\(baseID)_time", kind: .finishUnder(seconds: 28)),
                    LevelGoal(id: "\(baseID)_mistakes", kind: .noMistakes)
                ]
            }
        }
    }

    func dailyChallengeForToday() -> DailyChallengeDescriptor {
        let day = dayKey(for: Date())
        let seed = stableSeed(from: day)
        let activities = GameActivityKind.allCases
        let activity = activities[Int(seed % UInt64(activities.count))]
        let difficulties = GameDifficulty.allCases
        let difficulty = difficulties[Int((seed / 7) % UInt64(difficulties.count))]
        let index = Int((seed / 11) % 9)
        let level = GameLevel(
            id: "daily_\(day)_\(activity.rawValue)_\(difficulty.rawValue)_\(index)",
            index: index,
            difficulty: difficulty,
            activity: activity,
            isDailyChallenge: true
        )
        return DailyChallengeDescriptor(seed: seed, level: level, displayDate: day)
    }

    func markDailyChallengeCompletedIfNeeded(_ level: GameLevel, didWin: Bool) {
        guard level.isDailyChallenge, didWin else { return }
        let key = dayKey(for: Date())
        if !completedDailyChallengeDays.contains(key) {
            completedDailyChallengeDays.insert(key)
            UserDefaults.standard.set(Array(completedDailyChallengeDays), forKey: Keys.completedDailyChallengeDays)
        }
    }

    private func updateStreak(for date: Date) {
        let today = dayKey(for: date)
        if lastPlayedDay.isEmpty {
            currentStreakDays = 1
        } else if today == lastPlayedDay {
            // same day, keep streak
        } else if let last = dateFrom(dayKey: lastPlayedDay), Calendar.current.isDate(last, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date) {
            currentStreakDays += 1
        } else {
            currentStreakDays = 1
        }

        lastPlayedDay = today
        bestStreakDays = max(bestStreakDays, currentStreakDays)
        let defaults = UserDefaults.standard
        defaults.set(currentStreakDays, forKey: Keys.currentStreakDays)
        defaults.set(bestStreakDays, forKey: Keys.bestStreakDays)
        defaults.set(lastPlayedDay, forKey: Keys.lastPlayedDay)
    }

    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func dateFrom(dayKey: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }

    private func stableSeed(from dayKey: String) -> UInt64 {
        dayKey.utf8.reduce(UInt64(1469598103934665603)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1099511628211
        }
    }

    // MARK: - Achievements (computed)

    enum Achievement: String, CaseIterable, Identifiable {
        case firstPlay
        case starCollector
        case perfectionist
        case longSession
        case multiGame

        var id: String { rawValue }

        var title: String {
            switch self {
            case .firstPlay:
                return "First Puzzle"
            case .starCollector:
                return "Star Collector"
            case .perfectionist:
                return "Perfect Run"
            case .longSession:
                return "Endless Focus"
            case .multiGame:
                return "Versatile Player"
            }
        }

        var description: String {
            switch self {
            case .firstPlay:
                return "Finish any level for the first time."
            case .starCollector:
                return "Earn at least 30 total stars."
            case .perfectionist:
                return "Finish a level with 3 stars."
            case .longSession:
                return "Play for more than 30 minutes in total."
            case .multiGame:
                return "Complete levels in all three activities."
            }
        }
    }

    var totalStars: Int {
        starsPerLevel.values.reduce(0, +)
    }

    var hasPerfectLevel: Bool {
        starsPerLevel.values.contains(3)
    }

    var completedActivityKinds: Set<String> {
        let ids = starsPerLevel.keys.filter { (starsPerLevel[$0] ?? 0) > 0 }
        let kinds = ids.compactMap { id -> String? in
            let components = id.split(separator: "_")
            return components.first.map(String.init)
        }
        return Set(kinds)
    }

    var unlockedAchievements: [Achievement] {
        var result: [Achievement] = []
        if totalActivitiesPlayed > 0 {
            result.append(.firstPlay)
        }
        if totalStars >= 30 {
            result.append(.starCollector)
        }
        if hasPerfectLevel {
            result.append(.perfectionist)
        }
        if totalPlayTime >= 30 * 60 {
            result.append(.longSession)
        }
        if completedActivityKinds.count >= 3 {
            result.append(.multiGame)
        }
        return result
    }

    // MARK: - Reset

    func resetAll() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.starsPerLevel)
        defaults.removeObject(forKey: Keys.unlockedLevelIndex)
        defaults.removeObject(forKey: Keys.totalPlayTime)
        defaults.removeObject(forKey: Keys.totalActivitiesPlayed)
        defaults.removeObject(forKey: Keys.hasSeenOnboarding)
        defaults.removeObject(forKey: Keys.currentStreakDays)
        defaults.removeObject(forKey: Keys.bestStreakDays)
        defaults.removeObject(forKey: Keys.lastPlayedDay)
        defaults.removeObject(forKey: Keys.adaptivePerformanceByTrack)
        defaults.removeObject(forKey: Keys.completedDailyChallengeDays)

        starsPerLevel = [:]
        unlockedLevelIndex = [:]
        totalPlayTime = 0
        totalActivitiesPlayed = 0
        currentStreakDays = 0
        bestStreakDays = 0
        lastPlayedDay = ""
        adaptivePerformanceByTrack = [:]
        completedDailyChallengeDays = []
        hasSeenOnboarding = false

        NotificationCenter.default.post(name: AppStorageManager.resetNotification, object: nil)
    }
}

