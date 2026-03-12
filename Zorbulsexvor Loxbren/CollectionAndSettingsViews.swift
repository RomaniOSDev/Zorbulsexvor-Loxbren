//
//  CollectionAndSettingsViews.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI
import StoreKit
import UIKit

struct CollectionRootView: View {
    @ObservedObject private var storage = AppStorageManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summarySection
                    achievementsSection
                    starsPerActivitySection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(AppScreenBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Collection")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                }
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            HStack(spacing: 12) {
                statCard(title: "Total stars", value: "\(storage.totalStars)", icon: "star.fill")
                statCard(title: "Sessions", value: "\(storage.totalActivitiesPlayed)", icon: "gamecontroller.fill")
            }
            HStack(spacing: 12) {
                statCard(title: "Current streak", value: "\(storage.currentStreakDays)", icon: "flame.fill")
                statCard(title: "Best streak", value: "\(storage.bestStreakDays)", icon: "calendar.badge.clock")
            }
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.appAccent)
                Spacer()
            }
            Text(value)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.appTextPrimary)
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .appPanel(cornerRadius: 16, elevated: false)
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievements")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            if storage.unlockedAchievements.isEmpty {
                Text("Play levels to unlock unique badges.")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(AppStorageManager.Achievement.allCases) { achievement in
                        let unlocked = storage.unlockedAchievements.contains(where: { $0 == achievement })
                        HStack(spacing: 10) {
                            Circle()
                                .fill(unlocked ? Color.appAccent : Color.appSurface)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: unlocked ? "checkmark" : "lock.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(unlocked ? .appTextPrimary : .appTextSecondary)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(achievement.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.appTextPrimary)
                                Text(achievement.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .appPanel(cornerRadius: 14, elevated: false)
                    }
                }
            }
        }
    }

    private var starsPerActivitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Star breakdown")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 8) {
                ForEach(GameActivityKind.allCases) { kind in
                    HStack {
                        Text(kind.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        let total = totalStars(for: kind)
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.appAccent)
                                .font(.system(size: 12))
                            Text("\(total)")
                                .font(.system(size: 13))
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    .padding(10)
                    .appPanel(cornerRadius: 14, elevated: false)
                }
            }
        }
    }

    private func totalStars(for kind: GameActivityKind) -> Int {
        let prefix = "\(kind.rawValue)_"
        return storage.starsPerLevel.reduce(into: 0) { partial, entry in
            if entry.key.hasPrefix(prefix) {
                partial += entry.value
            }
        }
    }
}

struct SettingsRootView: View {
    @ObservedObject private var storage = AppStorageManager.shared
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    statsSection
                    supportSection
                    resetSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(AppScreenBackground())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                }
            }
            .alert("Reset all progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    storage.resetAll()
                }
            } message: {
                Text("This will clear stars, unlocked levels, statistics, and achievements.")
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 8) {
                statRow(title: "Total play time", value: formatted(time: storage.totalPlayTime))
                statRow(title: "Levels played", value: "\(storage.totalActivitiesPlayed)")
                statRow(title: "Total stars", value: "\(storage.totalStars)")
                statRow(title: "Current streak", value: "\(storage.currentStreakDays) days")
                statRow(title: "Best streak", value: "\(storage.bestStreakDays) days")
                statRow(title: "Daily challenges won", value: "\(storage.completedDailyChallengeDays.count)")
            }
            .padding(12)
            .appPanel(cornerRadius: 16)
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

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            Button {
                showResetAlert = true
            } label: {
                Text("Reset all progress")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.clear)
            }
            .buttonStyle(AppSecondaryButtonStyle())
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Support")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 8) {
                Button {
                    rateApp()
                } label: {
                    supportRow(title: "Rate Us", icon: "star.bubble.fill")
                }
                .buttonStyle(.plain)

                Button {
                    openPrivacyPolicy()
                } label: {
                    supportRow(title: "Privacy Policy", icon: "hand.raised.fill")
                }
                .buttonStyle(.plain)

                Button {
                    openTerms()
                } label: {
                    supportRow(title: "Terms of Use", icon: "doc.text.fill")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func supportRow(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.appAccent)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Image(systemName: "arrow.up.right")
                .foregroundColor(.appTextSecondary)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(12)
        .appPanel(cornerRadius: 14, elevated: false)
    }

    private func openPrivacyPolicy() {
        if let url = URL(string: "https://zorbulsexvorloxbren110.site/privacy/27") {
            UIApplication.shared.open(url)
        }
    }

    private func openTerms() {
        if let url = URL(string: "https://zorbulsexvorloxbren110.site/terms/27") {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func formatted(time: TimeInterval) -> String {
        let seconds = Int(time.rounded())
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

