//
//  WebviewVCRepresentable.swift
//  Zorbulsexvor Loxbren
//
//  Created by Nguyen Minhthinh on 12.03.2026.
//

import SwiftUI
import UIKit

struct WebviewVCRepresentable: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> WebviewVC {
        WebviewVC(url: url)
    }

    func updateUIViewController(_ uiViewController: WebviewVC, context: Context) {}
}
