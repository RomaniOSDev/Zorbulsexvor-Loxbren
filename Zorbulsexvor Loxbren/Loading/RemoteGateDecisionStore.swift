//
//  RemoteGateDecisionStore.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Foundation

/// Persists the first remote gate outcome; later responses do not override it.
enum RemoteGateDecisionStore {
    private static let decidedKey = "remote_gate_decided_v1"
    private static let isWhiteKey = "remote_gate_is_white_v1"
    private static let savedURLKey = "remote_gate_saved_url_v1"

    static var hasDecided: Bool {
        get { UserDefaults.standard.bool(forKey: decidedKey) }
        set { UserDefaults.standard.set(newValue, forKey: decidedKey) }
    }

    static var isWhiteRoute: Bool {
        get { UserDefaults.standard.bool(forKey: isWhiteKey) }
        set { UserDefaults.standard.set(newValue, forKey: isWhiteKey) }
    }

    static var savedWebURLString: String? {
        get { UserDefaults.standard.string(forKey: savedURLKey) }
        set { UserDefaults.standard.set(newValue, forKey: savedURLKey) }
    }

    static func markWhite() {
        hasDecided = true
        isWhiteRoute = true
        savedWebURLString = nil
    }

    static func markGray(url: URL) {
        hasDecided = true
        isWhiteRoute = false
        savedWebURLString = url.absoluteString
    }
}
