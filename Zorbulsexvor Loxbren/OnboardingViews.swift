//
//  OnboardingViews.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI

private struct OnboardingPageData: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let accentText: String
}

struct OnboardingContainerView: View {
    @ObservedObject private var storage = AppStorageManager.shared
    @State private var currentIndex: Int = 0
    @State private var animateShape: Bool = false

    private let pages: [OnboardingPageData] = [
        .init(
            title: "Signal Atlas is unstable",
            subtitle: "Neon fragments drift through broken glyph zones. Each node restores one missing shard.",
            accentText: "Recover the map one chapter at a time."
        ),
        .init(
            title: "Modifiers rewrite the rules",
            subtitle: "Chrono Lock, Echo Shift, and Precision Seal reshape each run with unique pressure.",
            accentText: "Learn each modifier to stay in control."
        ),
        .init(
            title: "Daily Echo sync",
            subtitle: "A shared daily signal appears every day with a fixed seed and your own ghost time to beat.",
            accentText: "Return daily and extend your streak."
        )
    ]

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $currentIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page, index: index, animateShape: animateShape)
                        .padding(.horizontal, 24)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    animateShape.toggle()
                }
            }

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.appPrimary : Color.appTextSecondary.opacity(0.4))
                        .frame(width: index == currentIndex ? 10 : 7, height: index == currentIndex ? 10 : 7)
                        .animation(.easeInOut(duration: 0.25), value: currentIndex)
                }
            }

            HStack(spacing: 12) {
                if currentIndex < pages.count - 1 {
                    Button(action: completeOnboarding) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(AppSecondaryButtonStyle())
                }

                Button(action: advanceOrFinish) {
                    Text(currentIndex == pages.count - 1 ? "Start playing" : "Next")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(AppPrimaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .padding(.top, 32)
        .background(AppScreenBackground())
    }

    private func advanceOrFinish() {
        if currentIndex < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        storage.hasSeenOnboarding = true
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPageData
    let index: Int
    let animateShape: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            PixelPuzzleIllustration(index: index, animateShape: animateShape)
                .frame(height: 240)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)

                Text(page.accentText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appAccent)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)

            Spacer()
        }
    }
}

private struct PixelPuzzleIllustration: View {
    let index: Int
    let animateShape: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let unit = size / 10

            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface, Color.appSurface.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.appPrimary.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.24), radius: 14, x: 0, y: 8)

                switch index {
                case 0:
                    // Pixel grid motif
                    VStack(spacing: unit * 0.3) {
                        ForEach(0..<4, id: \.self) { row in
                            HStack(spacing: unit * 0.3) {
                                ForEach(0..<4, id: \.self) { column in
                                    let phase = Double(row * 4 + column) / 10
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(colorFor(row: row, column: column))
                                        .frame(width: unit, height: unit)
                                        .scaleEffect(animateShape ? 0.9 + 0.1 * CGFloat(sin(phase * .pi * 2)) : 1.0)
                                        .animation(
                                            .easeInOut(duration: 1.2)
                                                .repeatForever(autoreverses: true)
                                                .delay(phase * 0.15),
                                            value: animateShape
                                        )
                                }
                            }
                        }
                    }
                case 1:
                    // Star track
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                            .foregroundColor(.appTextSecondary.opacity(0.5))
                            .padding(size * 0.16)

                        HStack(spacing: unit * 1.4) {
                            ForEach(0..<3, id: \.self) { i in
                                StarShape(points: 5, innerRatio: 0.4)
                                    .fill(i == 0 ? Color.appPrimary : Color.appAccent)
                                    .frame(width: unit * 1.7, height: unit * 1.7)
                                    .shadow(color: (i == 0 ? Color.appPrimary : Color.appAccent).opacity(0.7), radius: i == 0 ? 16 : 8, x: 0, y: 0)
                                    .scaleEffect(animateShape && i == 0 ? 1.1 : 1.0)
                                    .animation(
                                        .spring(response: 0.9, dampingFraction: 0.6)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.12),
                                        value: animateShape
                                    )
                            }
                        }
                    }
                default:
                    // Mixed shapes
                    ZStack {
                        Circle()
                            .fill(Color.appAccent.opacity(0.3))
                            .frame(width: size * 0.55, height: size * 0.55)
                            .offset(x: -size * 0.12, y: -size * 0.1)

                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.appPrimary.opacity(0.4))
                            .frame(width: size * 0.55, height: size * 0.35)
                            .offset(x: size * 0.16, y: size * 0.1)

                        Canvas { context, canvasSize in
                            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                            var path = Path()
                            path.move(to: CGPoint(x: center.x, y: center.y - unit * 1.6))
                            path.addLine(to: CGPoint(x: center.x + unit * 1.6, y: center.y + unit * 1.6))
                            path.addLine(to: CGPoint(x: center.x - unit * 1.6, y: center.y + unit * 1.6))
                            path.closeSubpath()

                            var style = GraphicsContext.Shading.color(.appSurface)
                            context.fill(path, with: style)

                            let pulse = animateShape ? 0.1 : 0
                            let glowRect = CGRect(x: center.x - unit * (1.2 + pulse),
                                                  y: center.y - unit * 0.3,
                                                  width: unit * (2.4 + 2 * pulse),
                                                  height: unit * 0.6)
                            context.fill(
                                Path(roundedRect: glowRect, cornerRadius: unit * 0.3),
                                with: .color(.appAccent)
                            )
                        }
                        .frame(width: size * 0.7, height: size * 0.7)
                        .scaleEffect(animateShape ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: animateShape)
                    }
                }
            }
        }
    }

    private func colorFor(row: Int, column: Int) -> Color {
        switch (row + column) % 3 {
        case 0: return .appPrimary
        case 1: return .appAccent
        default: return .appSurface
        }
    }
}

struct StarShape: Shape {
    let points: Int
    let innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()

        let angle = .pi * 2 / Double(points * 2)

        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? radius : radius * innerRatio
            let x = center.x + CGFloat(cos(Double(i) * angle - .pi / 2)) * r
            let y = center.y + CGFloat(sin(Double(i) * angle - .pi / 2)) * r

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        return path
    }
}

