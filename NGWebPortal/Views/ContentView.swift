//
//  ContentView.swift
//  NGWebPortal
//
//  Main Sysop Console and Waiting For Caller Screen
//
//  ⏰ ARTIFACT GENERATED: 2025 OCT 13 19:53
//  🔑 VERSION: TIMESTAMPED-FRESH

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Text("Server View - Coming Soon")
                .tabItem {
                    Label("Server", systemImage: "globe")
                }
                .tag(0)
            
            CustomizeView()
                .tabItem {
                    Label("Customize", systemImage: "paintbrush")
                }
                .tag(1)
            
            BlogEditorView()
                .tabItem {
                    Label("Blog", systemImage: "doc.text")
                }
                .tag(2)
            
            PortfolioListView()
                .tabItem {
                    Label("Portfolio", systemImage: "folder")
                }
                .tag(3)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BlogPost.self, PortfolioProject.self], inMemory: true)
}
