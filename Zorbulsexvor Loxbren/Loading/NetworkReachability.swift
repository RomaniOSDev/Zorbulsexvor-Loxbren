//
//  NetworkReachability.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import Foundation
import Network

enum NetworkReachability {
    /// One-shot check after the path monitor delivers its first update.
    static func isReachableNow() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkReachability.once")
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            monitor.start(queue: queue)
        }
    }
}
