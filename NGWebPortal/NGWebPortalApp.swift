//
//  NGWebPortalApp.swift
//  NGWebPortal
//
//  Main app entry point with SwiftData configuration
//
//  ⏰ ARTIFACT GENERATED: 2025 OCT 13 20:10
//  🔑 VERSION: TIMESTAMPED-FRESH

import SwiftUI
import SwiftData

@main
struct NGWebPortalApp: App {
    let webServer = WebServer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(webServer)
                .modelContainer(for: [BlogPost.self, PortfolioProject.self])
        }
    }
}
