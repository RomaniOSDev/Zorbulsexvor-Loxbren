//
//  DesignSystem.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI

struct AppScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.appBackground,
                Color.appBackground.opacity(0.96),
                Color.appSurface.opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.appTextPrimary.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 6)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface, Color.appSurface.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.appTextSecondary.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

extension View {
    @ViewBuilder
    func `if`<Transformed: View>(_ condition: Bool, transform: (Self) -> Transformed) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    func appPanel(cornerRadius: CGFloat = 16, elevated: Bool = true) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.95), Color.appSurface.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.appTextPrimary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(elevated ? 0.24 : 0.16), radius: elevated ? 14 : 8, x: 0, y: elevated ? 8 : 4)
        .shadow(color: Color.appAccent.opacity(elevated ? 0.12 : 0.07), radius: elevated ? 8 : 4, x: 0, y: 0)
    }
}

