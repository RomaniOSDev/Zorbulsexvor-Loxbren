//
//  AppGateRootView.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI
import UIKit

struct AppGateRootView: View {
    @StateObject private var flow = LoadingFlowViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            switch flow.phase {
            case .loading:
                LoadingView()
            case .white:
                ContentView()
            case .gray(let url):
                WebviewVCRepresentable(url: url)
                    .ignoresSafeArea()
            case .grayAwaitingNetwork:
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 14) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 40))
                        Text("Network required")
                            .font(.headline)
                        Text("Turn on Wi‑Fi or cellular data to continue.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.white)
                    .padding()
                }
            }
        }
        .onAppear { flow.onAppear() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await flow.retryWhenNetworkMayBeAvailable() }
            }
        }
        .alert("Open Settings", isPresented: $flow.showNetworkSettingsAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This content needs an internet connection. You can enable Wi‑Fi or cellular data in Settings.")
        }
    }
}
