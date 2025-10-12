//
//  NGWebPortalApp.swift
//  NGWebPortal
//
//  Main app entry point with SwiftData configuration
//

import SwiftUI
import SwiftData

@main
struct NGWebPortalApp: App {
    let webServer = WebServer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(webServer)
                .modelContainer(for: BlogPost.self)
        }
    }
}
