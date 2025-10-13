//
//  SettingsView.swift
//  NGWebPortal
//
//  Application settings and preferences interface
//

import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

struct SettingsView: View {
    @State private var siteName: String = ""
    @State private var siteTagline: String = ""
    @State private var blogTitle: String = ""
    @State private var blogTagline: String = ""
    @State private var outputDirectory: String = ""
    @State private var serverPort: String = ""
    
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
        let settings = SettingsManager.shared.loadSettings()
        siteName = settings.siteName
        siteTagline = settings.siteTagline
        blogTitle = settings.blogTitle
        blogTagline = settings.blogTagline
        outputDirectory = settings.outputDirectory
        serverPort = String(settings.serverPort)
    }
    
    private func saveSettings() {
        var settings = SettingsManager.shared.loadSettings()
        settings.siteName = siteName
        settings.siteTagline = siteTagline
        settings.blogTitle = blogTitle
        settings.blogTagline = blogTagline
        settings.outputDirectory = outputDirectory
        if let port = Int(serverPort) {
            settings.serverPort = port
        }
        SettingsManager.shared.saveSettings(settings)
    }
    
    private func selectOutputDirectory() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Output Directory"
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url.path
        }
        #else
        // Not supported on this platform
        #endif
    }
}

#Preview {
    SettingsView()
}
