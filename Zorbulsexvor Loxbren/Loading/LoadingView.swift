//
//  LoadingView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI

/// Shown at cold start while device parameters are collected and the remote gate request runs.
struct LoadingView: View {
    var body: some View {
        ZStack {
            AppScreenBackground()
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.25)
                    .tint(Color.appAccent)
                Text("Loading…")
                    .font(.headline)
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }
}
