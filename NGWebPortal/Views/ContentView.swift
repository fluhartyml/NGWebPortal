//
//  ContentView.swift
//  NGWebPortal
//
//  Main window with tabbed navigation for all features
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var server = WebServer()
    
    var body: some View {
        TabView {
            ServerView(server: server)
                .tabItem {
                    Label("Server", systemImage: "server.rack")
                }
            
            CustomizeView()
                .tabItem {
                    Label("Customize", systemImage: "paintbrush")
                }
            
            BlogEditorView()
                .tabItem {
                    Label("Blog", systemImage: "doc.text")
                }
            
            PortfolioListView()
                .tabItem {
                    Label("Portfolio", systemImage: "folder")
                }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BlogPost.self, PortfolioProject.self], inMemory: true)
}
