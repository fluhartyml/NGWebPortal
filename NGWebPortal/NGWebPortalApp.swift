//
//  NGWebPortalApp.swift
//  NGWebPortal
//
//  Created by Michael Fluharty on 10/11/25.
//

import SwiftUI
import SwiftData

@main
struct NGWebPortalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SiteSettings.self,
            BlogPost.self,
            PortfolioProject.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
