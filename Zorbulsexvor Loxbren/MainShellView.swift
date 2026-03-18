//
//  MainShellView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI

struct MainShellView: View {
    @State private var showCollection = false
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            HomeView()
            HStack(spacing: 10) {
                Button {
                    showCollection = true
                } label: {
                    Label("Collection", systemImage: "star.square.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                .buttonStyle(AppSecondaryButtonStyle())

                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                .buttonStyle(AppSecondaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(AppScreenBackground())
        .sheet(isPresented: $showCollection) {
            CollectionRootView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsRootView()
        }
    }
}

