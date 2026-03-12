//
//  ContentView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject private var storage = AppStorageManager.shared

    var body: some View {
        Group {
            if storage.hasSeenOnboarding {
                MainShellView()
            } else {
                OnboardingContainerView()
            }
        }
        .background(AppScreenBackground())
    }
}

