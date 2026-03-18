//
//  PlayRootView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var storage = AppStorageManager.shared
    @StateObject private var viewModel = HomeViewModel()
    @State private var path: [PlayRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    atlasHeader
                    chapterStrip
                    chapterPanel
                    dailyChallengePanel
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(AppScreenBackground())
            .navigationTitle("Atlas")
            .navigationBarTitleDisplayMode(.inline)
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
            if let first = viewModel.chapters.first?.id {
                viewModel.selectedChapterID = first
            }
        }
    }

    private var atlasHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signal Atlas")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)
            Text("Navigate handcrafted chapters and decode fractured neon glyphs.")
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 10) {
                pill(title: "Streak", value: "\(storage.currentStreakDays)d")
                pill(title: "Best", value: "\(storage.bestStreakDays)d")
                pill(title: "Nodes", value: "\(storage.completedAtlasNodeIDs.count)")
            }
        }
        .padding(14)
        .appPanel(cornerRadius: 18)
    }

    private func pill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 11)).foregroundColor(.appTextSecondary)
            Text(value).font(.system(size: 14, weight: .semibold)).foregroundColor(.appTextPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.appBackground.opacity(0.35)))
    }

    private var chapterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.chapters) { chapter in
                    let selected = chapter.id == viewModel.selectedChapterID
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            viewModel.selectedChapterID = chapter.id
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: chapter.accentSymbol)
                            Text(chapter.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selected ? .appTextPrimary : .appTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selected ? Color.appPrimary : Color.appSurface)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var chapterPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let chapter = viewModel.selectedChapter {
                Text(chapter.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text(chapter.lore)
                    .font(.system(size: 13))
                    .foregroundColor(.appTextSecondary)

                ProgressView(value: viewModel.completionRatio(chapter: chapter, storage: storage))
                    .tint(.appAccent)

                VStack(spacing: 10) {
                    ForEach(Array(chapter.nodes.enumerated()), id: \.element.id) { idx, node in
                        AtlasNodeCard(
                            node: node,
                            isUnlocked: viewModel.isNodeUnlocked(chapterID: chapter.id, nodeID: node.id, storage: storage),
                            isCompleted: storage.isAtlasNodeCompleted(node.id),
                            onPlay: { path.append(.activity(node.level)) }
                        )
                        if idx < chapter.nodes.count - 1 {
                            HStack {
                                Spacer()
                                Rectangle()
                                    .fill(Color.appTextSecondary.opacity(0.35))
                                    .frame(width: 2, height: 16)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .appPanel(cornerRadius: 18)
    }

    private var dailyChallengePanel: some View {
        let challenge = storage.dailyChallengeForToday()
        let completed = storage.completedDailyChallengeDays.contains(challenge.displayDate)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Daily Echo")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            Button {
                path.append(.activity(challenge.level))
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(challenge.level.activity.title)
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        Text(challenge.level.modifier?.title ?? "Modifier")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.appAccent)
                    }
                    .font(.system(size: 15, weight: .semibold))

                    Text(completed ? "Completed today. Beat your own ghost time." : "Shared daily seed with fixed rules.")
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)

                    if let best = storage.bestTimeForTodayDailyChallenge() {
                        Text("Ghost target: \(formatted(time: best))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appAccent)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .appPanel(cornerRadius: 16, elevated: !completed)
        }
    }

    @ViewBuilder
    private func activityView(for level: GameLevel) -> some View {
        let adaptive = storage.adaptiveModifier(for: trackID(for: level))
        let goals = storage.levelGoals(for: level)
        let seed = stableSeed(for: level)
        switch level.activity {
        case .pixelMatch:
            PixelMatchGameView(level: level, adaptiveModifier: adaptive, goals: goals, seed: seed, onFinished: handleResult)
        case .shapeSort:
            ShapeSortGameView(level: level, adaptiveModifier: adaptive, goals: goals, seed: seed, onFinished: handleResult)
        case .patternRecall:
            PatternRecallGameView(level: level, adaptiveModifier: adaptive, goals: goals, seed: seed, onFinished: handleResult)
        }
    }

    private func handleResult(_ summary: GameResultSummary) {
        let before = storage.unlockedAchievements
        storage.updateStars(for: summary.level.id, newStars: summary.stars)
        storage.addPlaySession(duration: summary.time)
        storage.recordOutcome(for: trackID(for: summary.level), didWin: summary.didWin)
        storage.markDailyChallengeCompletedIfNeeded(summary.level, didWin: summary.didWin)
        storage.updateBestDailyTimeIfNeeded(summary.level, time: summary.time)
        if summary.didWin, let nodeID = summary.level.nodeID {
            storage.completeAtlasNode(nodeID)
        }
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

    private func formatted(time: TimeInterval) -> String {
        let seconds = Int(time.rounded())
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private enum PlayRoute: Hashable {
    case activity(GameLevel)
    case result(GameResultSummary)
}

private struct AtlasNodeCard: View {
    let node: AtlasNode
    let isUnlocked: Bool
    let isCompleted: Bool
    let onPlay: () -> Void

    var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Color.appPrimary : Color.appSurface.opacity(0.6))
                        .frame(width: 34, height: 34)
                    Image(systemName: isCompleted ? "checkmark" : (isUnlocked ? "play.fill" : "lock.fill"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.appTextPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(node.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(1)
                    Text(node.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                    Text(node.level.modifier?.title ?? "")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appAccent)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.appTextSecondary)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appPanel(cornerRadius: 14, elevated: isUnlocked)
            .opacity(isUnlocked ? 1 : 0.65)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

