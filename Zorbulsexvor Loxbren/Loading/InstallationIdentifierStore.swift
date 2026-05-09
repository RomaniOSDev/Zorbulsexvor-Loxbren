//
//  InstallationIdentifierStore.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Foundation

final class InstallationIdentifierStore {
    static let shared = InstallationIdentifierStore()

    private let key = "installation_uuid_v1"

    private init() {}

    /// Stable per-install UUID for query param and OneSignal External ID.
    func installationUUID() -> String {
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: key)
        return fresh
    }
}
