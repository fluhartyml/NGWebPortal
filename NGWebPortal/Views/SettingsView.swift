//
//  SettingsView.swift
//  NGWebPortal
//
//  Application settings and preferences interface
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    
    @State private var siteName: String = ""
    @State private var siteTagline: String = ""
    @State private var blogTitle: String = ""
    @State private var blogTagline: String = ""
    @State private var outputDirectory: String = ""
    @State private var serverPort: String = ""
    
    private var currentSettings: AppSettings? {
        settings.first
    }
    
    var body: some View {
        Form {
            Section("Site Information") {
                TextField("Site Name", text: $siteName)
                TextField("Site Tagline", text: $siteTagline)
            }
            
            Section("Blog Settings") {
                TextField("Blog Title", text: $blogTitle)
                TextField("Blog Tagline", text: $blogTagline)
            }
            
            Section("Publishing") {
                HStack {
                    TextField("Output Directory", text: $outputDirectory)
                    Button("Choose...") {
                        selectOutputDirectory()
                    }
                }
                TextField("Server Port", text: $serverPort)
                    .frame(width: 100)
            }
            
            Section {
                Button("Save Settings") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if let settings = currentSettings {
            siteName = settings.siteName
            siteTagline = settings.siteTagline
            blogTitle = settings.blogTitle
            blogTagline = settings.blogTagline
            outputDirectory = settings.outputDirectory
            serverPort = String(settings.serverPort)
        } else {
            // Create default settings
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            loadSettings()
        }
    }
    
    private func saveSettings() {
        if let settings = currentSettings {
            settings.siteName = siteName
            settings.siteTagline = siteTagline
            settings.blogTitle = blogTitle
            settings.blogTagline = blogTagline
            settings.outputDirectory = outputDirectory
            if let port = Int(serverPort) {
                settings.serverPort = port
            }
            try? modelContext.save()
        }
    }
    
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Output Directory"
        
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url.path
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}
