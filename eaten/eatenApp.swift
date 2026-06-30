//
//  eatenApp.swift
//  eaten
//
//  Created by Alicia Zhou on 6/23/26.
//

import SwiftUI

@main
struct eatenApp: App {
    init() {
        BrandFont.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Default everything to PolySans Neutral; views override sizes as needed.
                .environment(\.font, .poly(17, relativeTo: .body))
        }
    }
}
