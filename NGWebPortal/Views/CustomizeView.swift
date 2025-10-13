//
//  CustomizeView.swift
//  NGWebPortal
//
//  Site customization interface for theme and content settings
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct CustomizeView: View {
    @State private var settings: SiteSettings = .default
    
    @State private var logoImage: NSImage?
    @State private var accentColorRed: Double = 0.0
    @State private var accentColorGreen: Double = 0.478
    @State private var accentColorBlue: Double = 1.0
    @State private var showingSavedAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Customize Your Site")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                // MARK: - Branding Section
                GroupBox("Branding") {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("Site Name:", text: $settings.siteName)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Tagline:", text: $settings.siteTagline)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Author Name:", text: $settings.authorName)
                            .textFieldStyle(.roundedBorder)
                        
                        Divider()
                        
                        // Logo Section - Always visible
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Company Logo")
                                .font(.headline)
                            
                            // Logo Preview
                            if let image = logoImage {
                                HStack {
                                    Image(nsImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 80)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(settings.logoFileName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            Button("Change Logo...") {
                                                selectLogoImage()
                                            }
                                            
                                            Button("Remove Logo") {
                                                logoImage = nil
                                                settings.logoFileName = ""
                                                // Restore default app icon
                                                NSApp.applicationIconImage = nil
                                                print("✅ Logo removed, app icon restored to default")
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(.red)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            } else {
                                // No logo yet
                                HStack {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                        .frame(width: 80, height: 80)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("No logo uploaded")
                                            .foregroundColor(.secondary)
                                        
                                        Button("Choose Logo Image...") {
                                            selectLogoImage()
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            
                            Text("Logo appears in header, footer, and as app icon. Recommended: Square image, 512x512px or larger.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Display options - separate from logo upload
                        Toggle("Hide Company Name in Header", isOn: $settings.useLogo)
                            .toggleStyle(.switch)
                        
                        Text("When enabled, only the logo will appear in the header (no text).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // MARK: - Colors Section
                GroupBox("Colors") {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Accent Color")
                            .font(.headline)
                        
                        HStack {
                            Rectangle()
                                .fill(Color(red: accentColorRed, green: accentColorGreen, blue: accentColorBlue))
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("R:")
                                        .frame(width: 20)
                                    Slider(value: $accentColorRed, in: 0...1)
                                    Text("\(Int(accentColorRed * 255))")
                                        .frame(width: 35)
                                }
                                HStack {
                                    Text("G:")
                                        .frame(width: 20)
                                    Slider(value: $accentColorGreen, in: 0...1)
                                    Text("\(Int(accentColorGreen * 255))")
                                        .frame(width: 35)
                                }
                                HStack {
                                    Text("B:")
                                        .frame(width: 20)
                                    Slider(value: $accentColorBlue, in: 0...1)
                                    Text("\(Int(accentColorBlue * 255))")
                                        .frame(width: 35)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // MARK: - Blog Settings
                GroupBox("Blog") {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("Blog Title:", text: $settings.blogTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Blog Tagline:", text: $settings.blogTagline)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                }
                
                // MARK: - Home Page Settings
                GroupBox("Home Page") {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("Hero Title:", text: $settings.homeHeroTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Hero Subtitle:", text: $settings.homeHeroSubtitle)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Call-to-Action Button:", text: $settings.homeCtaText)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                }
                
                // MARK: - About Page Settings
                GroupBox("About Page") {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("About Title:", text: $settings.aboutTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("About Content:")
                            .font(.headline)
                        
                        TextEditor(text: $settings.aboutContent)
                            .frame(height: 120)
                            .font(.system(.body, design: .default))
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    .padding()
                }
                
                // MARK: - Portfolio Settings
                GroupBox("Portfolio") {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("Portfolio Title:", text: $settings.portfolioTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Portfolio Tagline:", text: $settings.portfolioTagline)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                }
                
                // MARK: - Save Button
                HStack {
                    Spacer()
                    
                    Button("Save All Changes") {
                        saveSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .onAppear {
            loadSettings()
        }
        .alert("Settings Saved", isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your settings have been saved and the website has been regenerated!")
        }
    }
    
    // MARK: - Load Settings
    func loadSettings() {
        // Load from JSON
        settings = SettingsManager.shared.loadSettings()
        
        // Update color sliders from hex
        let rgb = SettingsManager.shared.rgbFromHex(settings.accentColor)
        accentColorRed = rgb.red
        accentColorGreen = rgb.green
        accentColorBlue = rgb.blue
        
        // Load logo image if exists
        loadLogoImage()
    }
    
    // MARK: - Load Logo Image
    func loadLogoImage() {
        guard !settings.logoFileName.isEmpty else {
            logoImage = nil
            NSApp.applicationIconImage = nil
            return
        }
        
        let imagesPath = (settings.outputDirectory as NSString).expandingTildeInPath
        let logoPath = (imagesPath as NSString).appendingPathComponent("images/\(settings.logoFileName)")
        
        if FileManager.default.fileExists(atPath: logoPath) {
            logoImage = NSImage(contentsOfFile: logoPath)
            
            // Restore custom app icon if logo exists
            if let appIcon = logoImage {
                NSApp.applicationIconImage = appIcon
                print("✅ App icon restored from saved logo")
            }
        }
    }
    
    // MARK: - Select Logo Image
    func selectLogoImage() {
        print("🔍 Opening file picker for logo selection...")
        
        let panel = NSOpenPanel()
        panel.title = "Choose Logo Image"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.message = "Select an image to use as your site logo"
        
        panel.begin { response in
            print("📁 File picker response: \(response == .OK ? "OK" : "Cancelled")")
            
            if response == .OK {
                if let url = panel.url {
                    print("📸 Selected file: \(url.path)")
                    self.copyLogoToSite(from: url)
                } else {
                    print("❌ No URL returned from file picker")
                }
            } else {
                print("⚠️ User cancelled file selection")
            }
        }
    }
    
    // MARK: - Copy Logo to Site
    func copyLogoToSite(from sourceURL: URL) {
        print("🚀 Starting logo copy process...")
        print("   Source: \(sourceURL.path)")
        
        // Start accessing security-scoped resource
        guard sourceURL.startAccessingSecurityScopedResource() else {
            print("❌ Failed to access security-scoped resource")
            return
        }
        defer {
            sourceURL.stopAccessingSecurityScopedResource()
            print("🔓 Released security-scoped resource")
        }
        
        let imagesDir = (settings.outputDirectory as NSString).expandingTildeInPath + "/images"
        let fileName = "logo.\(sourceURL.pathExtension)"
        let destinationURL = URL(fileURLWithPath: (imagesDir as NSString).appendingPathComponent(fileName))
        
        print("   Destination: \(destinationURL.path)")
        
        do {
            // Ensure images directory exists
            try FileManager.default.createDirectory(atPath: imagesDir, withIntermediateDirectories: true)
            print("✅ Images directory ready: \(imagesDir)")
            
            // Remove old logo if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
                print("🗑️  Removed old logo")
            }
            
            // Copy file
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            print("✅ Logo copied successfully to: \(destinationURL.path)")
            
            // Update state
            settings.logoFileName = fileName
            logoImage = NSImage(contentsOf: destinationURL)
            
            print("✅ Logo loaded into preview")
            
            // Set as app icon in Dock
            if let appIcon = logoImage {
                NSApp.applicationIconImage = appIcon
                print("✅ App icon updated in Dock")
            } else {
                print("⚠️ Logo image failed to load for app icon")
            }
            
        } catch {
            print("❌ Error copying logo: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Save Settings
    func saveSettings() {
        // Update accent color from sliders
        settings.accentColor = SettingsManager.shared.hexFromRGB(
            red: accentColorRed,
            green: accentColorGreen,
            blue: accentColorBlue
        )
        
        // Save to JSON
        SettingsManager.shared.saveSettings(settings)
        
        // Regenerate home page HTML
        SiteManager.shared.regenerateHomePage(settings: settings)
        
        showingSavedAlert = true
    }
}

#Preview {
    CustomizeView()
}
