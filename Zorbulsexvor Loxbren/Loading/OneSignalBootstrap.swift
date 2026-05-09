//
//  OneSignalBootstrap.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Foundation
import UIKit

#if canImport(OneSignalFramework)
import OneSignalFramework
#endif

enum OneSignalBootstrap {
    private static func appIdFromBundle() -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "OneSignalAppID") as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func configureIfNeeded(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        #if canImport(OneSignalFramework)
        guard let appId = appIdFromBundle() else { return }
        OneSignal.initialize(appId, withLaunchOptions: launchOptions)
        #endif
    }

    /// Call after installation UUID is known (same value as query param).
    static func loginExternalUserIfConfigured(externalId: String) {
        #if canImport(OneSignalFramework)
        guard appIdFromBundle() != nil else { return }
        OneSignal.login(externalId)
        #endif
    }
}
