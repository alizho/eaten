//
//  Theme.swift
//  eaten
//
//  Brand palette + reusable styling.
//

import SwiftUI

extension Color {
    /// Soft pale-green — the app background / "paper".
    static let eatenCream = Color(hex: 0xF0FFDD)
    /// Electric violet — primary accent.
    static let eatenViolet = Color(hex: 0x4705FF)
    /// Warm orange — secondary accent.
    static let eatenOrange = Color(hex: 0xFF6434)

    /// Tag pill palette (per Alicia's spec).
    static let tagFill = Color(hex: 0xC8DFB5)   // used at 45% opacity
    static let tagName = Color(hex: 0x5D714F)   // name text, full opacity
    static let tagCount = Color(hex: 0x94B57D)  // count text, 65% opacity

    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

enum Theme {
    /// Near-solid cream so cutouts read as floating objects (per the mockups).
    static var background: some View {
        Color.eatenCream.ignoresSafeArea()
    }
}
