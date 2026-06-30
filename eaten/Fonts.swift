//
//  Fonts.swift
//  eaten
//
//  Registers the bundled PolySans fonts at launch (works with a generated
//  Info.plist — no UIAppFonts array needed) and exposes brand-font helpers.
//

import SwiftUI
import CoreText

enum BrandFont {
    /// Register every .otf/.ttf in the app bundle. Call once at launch.
    static func register() {
        let exts = ["otf", "ttf"]
        let urls = exts.flatMap { Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: nil) ?? [] }
        guard !urls.isEmpty else { return }
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true) { _, _ in true }
    }
}

extension Font {
    /// PolySans Neutral — the everyday app font. `relativeTo` keeps Dynamic Type.
    static func poly(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("PolySans-Neutral", size: size, relativeTo: style)
    }

    /// PolySans Neutral Italic — reserved for the "eaten" wordmark.
    static func polyItalic(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("PolySans-NeutralItalic", size: size, relativeTo: style)
    }
}
