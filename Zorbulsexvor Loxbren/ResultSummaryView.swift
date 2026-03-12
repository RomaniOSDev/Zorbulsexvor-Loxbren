//
//  ResultSummaryView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI

struct ResultSummaryView: View {
    let summary: GameResultSummary
    let onNextLevel: (GameLevel?) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storage = AppStorageManager.shared
    @State private var animatedStars: Int = 0
    @State private var showBanner: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(summary.didWin ? "Level complete" : "Try again")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)

                    Text(summary.level.activity.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.top, 24)

                starRow

                statsSection
                goalsSection

                if !summary.newlyUnlockedAchievements.isEmpty {
                    bannerSection
                }

                buttonsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(AppScreenBackground())
        .onAppear {
            animateStars()
            if !summary.newlyUnlockedAchievements.isEmpty {
                withAnimation(.easeInOut(duration: 0.4).delay(0.4)) {
                    showBanner = true
                }
            }
        }
    }

    private var starRow: some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                let isFilled = index < animatedStars
                StarShape(points: 5, innerRatio: 0.45)
                    .fill(isFilled ? Color.appAccent : Color.appSurface)
                    .frame(width: 46, height: 46)
                    .shadow(color: isFilled ? Color.appAccent.opacity(0.9) : Color.clear,
                            radius: isFilled ? 18 : 0,
                            x: 0,
                            y: 0)
                    .scaleEffect(isFilled ? 1.1 : 0.95)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6)
                            .delay(Double(index) * 0.15),
                        value: animatedStars
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .appPanel(cornerRadius: 20)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 8) {
                statRow(title: "Time", value: formatted(time: summary.time))
                statRow(title: "Moves", value: "\(summary.moves)")
                statRow(title: "Mistakes", value: "\(summary.mistakes)")
                statRow(title: "Difficulty", value: summary.level.difficulty.title)
                statRow(title: "Current streak", value: "\(storage.currentStreakDays) days")
                if summary.adaptiveModifier != 0 {
                    statRow(title: "Adaptive mode", value: summary.adaptiveModifier < 0 ? "Eased" : "Boosted")
                }
            }
            .padding(12)
            .appPanel(cornerRadius: 16)
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Level goals")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            if summary.goals.isEmpty {
                Text("No goals configured for this level.")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(summary.goals) { goal in
                        let done = summary.completedGoals.contains(goal)
                        HStack {
                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(done ? .appAccent : .appTextSecondary)
                            Text(goal.title)
                                .font(.system(size: 14))
                                .foregroundColor(.appTextPrimary)
                            Spacer()
                        }
                        .padding(10)
                        .appPanel(cornerRadius: 12, elevated: false)
                    }
                }
            }
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.appTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appTextPrimary)
        }
    }

    private var bannerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New achievements")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            ZStack(alignment: .top) {
                if showBanner {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(summary.newlyUnlockedAchievements) { achievement in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(achievement.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.appTextPrimary)
                                Text(achievement.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.appTextSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appPrimary, Color.appAccent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.appPrimary.opacity(0.6), radius: 14, x: 0, y: 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            Button {
                let nextLevel = nextLevelFromCurrent()
                onNextLevel(nextLevel)
            } label: {
                Text(nextButtonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.clear)
            }
            .if(nextLevelFromCurrent() == nil) { view in
                view.buttonStyle(AppSecondaryButtonStyle())
            }
            .if(nextLevelFromCurrent() != nil) { view in
                view.buttonStyle(AppPrimaryButtonStyle())
            }
            .disabled(nextLevelFromCurrent() == nil)

            Button {
                let replay = summary.level
                onNextLevel(replay)
            } label: {
                Text("Retry")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.clear)
            }
            .buttonStyle(AppSecondaryButtonStyle())

            Button {
                dismiss()
            } label: {
                Text("Back to levels")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(.top, 8)
    }

    private func formatted(time: TimeInterval) -> String {
        let seconds = Int(time.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func nextLevelFromCurrent() -> GameLevel? {
        if summary.level.isDailyChallenge { return nil }
        let nextIndex = summary.level.index + 1
        let maxIndex = 8
        guard nextIndex <= maxIndex else { return nil }
        let id = "\(summary.level.activity.rawValue)_\(summary.level.difficulty.rawValue)_\(nextIndex)"
        return GameLevel(id: id, index: nextIndex, difficulty: summary.level.difficulty, activity: summary.level.activity)
    }

    private var nextButtonTitle: String {
        if summary.level.isDailyChallenge {
            return "Daily challenge complete"
        }
        return nextLevelFromCurrent() == nil ? "All levels complete" : "Next level"
    }

    private func animateStars() {
        animatedStars = 0
        let target = max(0, min(3, summary.stars))
        guard target > 0 else { return }
        for step in 1...target {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.15) {
                animatedStars = step
            }
        }
    }
}

