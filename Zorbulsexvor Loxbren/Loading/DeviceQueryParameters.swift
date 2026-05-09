//
//  DeviceQueryParameters.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Darwin
import Foundation
import UIKit

enum DeviceQueryParameters {
    static func buildItems(uuid: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: LoadingConfig.queryModelId, value: hardwareModelIdentifier()),
            URLQueryItem(name: LoadingConfig.queryOS, value: UIDevice.current.systemVersion),
            URLQueryItem(name: LoadingConfig.queryLang, value: preferredLanguageTag()),
            URLQueryItem(name: LoadingConfig.queryRegion, value: regionCode()),
            URLQueryItem(name: LoadingConfig.queryUUID, value: uuid)
        ]
    }

    private static func preferredLanguageTag() -> String {
        if let first = Locale.preferredLanguages.first, !first.isEmpty {
            return first
        }
        return "en"
    }

    private static func regionCode() -> String {
        if let id = Locale.current.region?.identifier, !id.isEmpty {
            return id
        }
        return "ZZ"
    }

    private static func hardwareModelIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &buffer, &size, nil, 0)
        let id = String(cString: buffer)
        return id.isEmpty ? "unknown" : id
    }
}
