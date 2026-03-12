//
//  PlayRootView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var storage = AppStorageManager.shared
    @State private var selectedDifficulty: GameDifficulty = .easy
    @State private var path: [PlayRoute] = []

    private let levelsPerDifficulty = 9

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    difficultyPicker
                    quickActionsSection
                    dailyChallengeCard
                    activityCards
                    levelSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(AppScreenBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Home")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                }
            }
            .navigationDestination(for: PlayRoute.self) { route in
                switch route {
                case .activity(let level):
                    activityView(for: level)
                case .result(let summary):
                    ResultSummaryView(summary: summary) { next in
                        if let nextLevel = next {
                            path.append(.activity(nextLevel))
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppStorageManager.resetNotification)) { _ in
            path = []
        }
    }

    private var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Difficulty")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            HStack(spacing: 8) {
                ForEach(GameDifficulty.allCases) { difficulty in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedDifficulty = difficulty
                        }
                    } label: {
                        Text(difficulty.title)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(selectedDifficulty == difficulty ? .appTextPrimary : .appTextSecondary)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedDifficulty == difficulty ? Color.appPrimary : Color.appSurface)
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pixel Puzzle Arena")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)

            Text("Build streaks, complete level goals, and master all mini games.")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 12) {
                statPill(title: "Streak", value: "\(storage.currentStreakDays)d")
                statPill(title: "Best", value: "\(storage.bestStreakDays)d")
                statPill(title: "Stars", value: "\(storage.totalStars)")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appPanel(cornerRadius: 18)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.appTextSecondary)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.appTextPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.appBackground.opacity(0.4))
        )
    }

    private var quickActionsSection: some View {
        HStack(spacing: 10) {
            Button {
                if let level = nextPlayableLevel() {
                    path.append(.activity(level))
                }
            } label: {
                actionTile(title: "Continue", subtitle: "Jump to next level", icon: "play.fill", usePrimary: true)
            }
            .buttonStyle(.plain)

            Button {
                if let level = randomUnlockedLevel() {
                    path.append(.activity(level))
                }
            } label: {
                actionTile(title: "Quick Mix", subtitle: "Random unlocked level", icon: "shuffle", usePrimary: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func actionTile(title: String, subtitle: String, icon: String, usePrimary: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appTextPrimary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.appBackground.opacity(0.35)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: usePrimary ? [Color.appPrimary, Color.appAccent] : [Color.appSurface, Color.appSurface.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appTextPrimary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(usePrimary ? 0.24 : 0.18), radius: usePrimary ? 10 : 7, x: 0, y: usePrimary ? 6 : 4)
    }

    private var activityCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activities")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(GameActivityKind.allCases) { kind in
                        Button {
                            if let firstLevel = level(for: kind, index: 0) {
                                path.append(.activity(firstLevel))
                            }
                        } label: {
                            ActivityCard(kind: kind, difficulty: selectedDifficulty, storage: storage)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 220, height: 120)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var dailyChallengeCard: some View {
        let challenge = storage.dailyChallengeForToday()
        let completedToday = storage.completedDailyChallengeDays.contains(challenge.displayDate)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Daily Challenge")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            Button {
                path.append(.activity(challenge.level))
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(challenge.level.activity.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Text(challenge.level.difficulty.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appAccent)
                    }
                    Text(completedToday ? "Completed today. Replay for a better run." : "One shared puzzle for today. Fixed layout for everyone.")
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    HStack {
                        Text(challenge.displayDate)
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                        Spacer()
                        Text(completedToday ? "Done" : "Play now")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.clear)
            }
            .buttonStyle(.plain)
            .if(completedToday) { view in
                view.appPanel(cornerRadius: 16)
            }
            .if(!completedToday) { view in
                view.background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appTextPrimary.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 6)
            }
        }
    }

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Levels")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(0..<levelsPerDifficulty, id: \.self) { index in
                    LevelCellView(levelIndex: index,
                                  difficulty: selectedDifficulty,
                                  storage: storage) { activity in
                        if let level = level(for: activity, index: index) {
                            path.append(.activity(level))
                        }
                    }
                }
            }
        }
    }

    private func level(for activity: GameActivityKind, index: Int) -> GameLevel? {
        guard index >= 0, index < levelsPerDifficulty else { return nil }
        let id = "\(activity.rawValue)_\(selectedDifficulty.rawValue)_\(index)"
        return GameLevel(id: id, index: index, difficulty: selectedDifficulty, activity: activity)
    }

    @ViewBuilder
    private func activityView(for level: GameLevel) -> some View {
        let modifier = storage.adaptiveModifier(for: trackID(for: level))
        let goals = storage.levelGoals(for: level)
        let seed = stableSeed(for: level)
        switch level.activity {
        case .pixelMatch:
            PixelMatchGameView(level: level, adaptiveModifier: modifier, goals: goals, seed: seed, onFinished: handleResult)
        case .shapeSort:
            ShapeSortGameView(level: level, adaptiveModifier: modifier, goals: goals, seed: seed, onFinished: handleResult)
        case .patternRecall:
            PatternRecallGameView(level: level, adaptiveModifier: modifier, goals: goals, seed: seed, onFinished: handleResult)
        }
    }

    private func handleResult(_ summary: GameResultSummary) {
        let before = storage.unlockedAchievements
        storage.updateStars(for: summary.level.id, newStars: summary.stars)
        storage.addPlaySession(duration: summary.time)
        storage.recordOutcome(for: trackID(for: summary.level), didWin: summary.didWin)
        storage.markDailyChallengeCompletedIfNeeded(summary.level, didWin: summary.didWin)
        storage.unlockNextLevelIfNeeded(
            for: trackID(for: summary.level),
            completedIndex: summary.level.index,
            maxIndex: levelsPerDifficulty - 1
        )
        let after = storage.unlockedAchievements
        let newOnes = after.filter { !before.contains($0) }
        let enriched = GameResultSummary(
            level: summary.level,
            stars: summary.stars,
            time: summary.time,
            moves: summary.moves,
            mistakes: summary.mistakes,
            didWin: summary.didWin,
            adaptiveModifier: summary.adaptiveModifier,
            goals: summary.goals,
            completedGoals: summary.completedGoals,
            newlyUnlockedAchievements: newOnes
        )
        path.append(.result(enriched))
    }

    private func trackID(for level: GameLevel) -> String {
        "\(level.activity.rawValue)_\(level.difficulty.rawValue)"
    }

    private func stableSeed(for level: GameLevel) -> UInt64 {
        level.id.utf8.reduce(UInt64(2166136261)) { hash, byte in
            (hash ^ UInt64(byte)) &* 16777619
        }
    }

    private func nextPlayableLevel() -> GameLevel? {
        let activity: GameActivityKind = .pixelMatch
        let unlocked = storage.highestUnlockedLevelIndex(for: "\(activity.rawValue)_\(selectedDifficulty.rawValue)")
        return level(for: activity, index: min(unlocked, levelsPerDifficulty - 1))
    }

    private func randomUnlockedLevel() -> GameLevel? {
        let activities = GameActivityKind.allCases
        guard let activity = activities.randomElement() else { return nil }
        let unlocked = storage.highestUnlockedLevelIndex(for: "\(activity.rawValue)_\(selectedDifficulty.rawValue)")
        let maxIndex = max(0, min(unlocked, levelsPerDifficulty - 1))
        let randomIndex = Int.random(in: 0...maxIndex)
        return level(for: activity, index: randomIndex)
    }
}

private enum PlayRoute: Hashable {
    case activity(GameLevel)
    case result(GameResultSummary)
}

private struct ActivityCard: View {
    let kind: GameActivityKind
    let difficulty: GameDifficulty
    let storage: AppStorageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(kind.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Text(difficulty.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.appSurface.opacity(0.9))
                    )
            }

            Text(kind.description)
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.appAccent)
                    .font(.system(size: 12))
                Text("\(totalStars)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(12)
        .appPanel(cornerRadius: 16, elevated: false)
    }

    private var totalStars: Int {
        let prefix = "\(kind.rawValue)_\(difficulty.rawValue)_"
        return storage.starsPerLevel.reduce(into: 0) { partial, entry in
            if entry.key.hasPrefix(prefix) {
                partial += entry.value
            }
        }
    }
}

private struct LevelCellView: View {
    let levelIndex: Int
    let difficulty: GameDifficulty
    let storage: AppStorageManager
    let onTapActivity: (GameActivityKind) -> Void

    private var activities: [GameActivityKind] { GameActivityKind.allCases }

    var body: some View {
        let unlockedIndex = storage.highestUnlockedLevelIndex(for: trackID)
        let isLocked = levelIndex > unlockedIndex
        let bestStars = activities.map { stars(for: $0) }.max() ?? 0

        Button {
            guard !isLocked else { return }
            if let activity = activities.max(by: { stars(for: $0) < stars(for: $1) }) ?? activities.first {
                onTapActivity(activity)
            }
        } label: {
            VStack(spacing: 6) {
                HStack {
                    Text("\(levelIndex + 1)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isLocked ? .appTextSecondary : .appTextPrimary)
                    Spacer()
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appTextSecondary)
                    }
                }

                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < bestStars ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(index < bestStars ? .appAccent : .appSurface)
                    }
                    Spacer()
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isLocked ? Color.appSurface.opacity(0.5) : Color.appSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.appTextPrimary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isLocked ? 0.1 : 0.2), radius: isLocked ? 4 : 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
    }

    private var trackID: String {
        "\(GameActivityKind.pixelMatch.rawValue)_\(difficulty.rawValue)"
    }

    private func stars(for activity: GameActivityKind) -> Int {
        let levelID = "\(activity.rawValue)_\(difficulty.rawValue)_\(levelIndex)"
        return storage.stars(for: levelID)
    }
}

