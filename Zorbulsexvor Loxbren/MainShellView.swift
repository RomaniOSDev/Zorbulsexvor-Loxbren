//
//  MainShellView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI

private enum MainTab: String, CaseIterable, Identifiable {
    case home
    case collection
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .collection: return "Collection"
        case .settings: return "Settings"
        }
    }
}

struct MainShellView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case .home:
                    HomeView()
                case .collection:
                    CollectionRootView()
                case .settings:
                    SettingsRootView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .background(AppScreenBackground())
    }
}

private struct CustomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 24) {
            ForEach(MainTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: iconName(for: tab))
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(selectedTab == tab ? .appPrimary : .appTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(selectedTab == tab ? Color.appSurface.opacity(0.9) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [Color.appBackground.opacity(0.98), Color.appSurface.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: -2)
    }

    private func iconName(for tab: MainTab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .collection: return "star.square.fill"
        case .settings: return "slider.horizontal.3"
        }
    }
}

