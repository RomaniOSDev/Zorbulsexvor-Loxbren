//
//  LoadingConfig.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Foundation

/// Remote gate: GET endpoint. Gray path: HTTP 200 + JSON `{"url":"https://…"}` (primary), or optional header Base64 URL (fallback).
enum LoadingConfig {
    /// Fallback gray: response header with Base64-encoded URL (tests / legacy). Production: replace name if needed.
    static let responseHeaderKey = "sto-per-kost"

    static let endpointURL = URL(string: "https://smtapp.cyou")!

    static let queryModelId = "model_id"
    static let queryOS = "os"
    static let queryLang = "lang"
    static let queryRegion = "rg"
    static let queryUUID = "uuid"
}
