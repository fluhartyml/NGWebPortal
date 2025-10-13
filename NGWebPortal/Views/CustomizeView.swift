//
//  CustomizeView.swift
//  NGWebPortal
//
//  Site customization interface for theme and content settings
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct CustomizeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]
    @Query private var allPosts: [BlogPost]
    
    @State private var siteName: String = ""
    @State private var tagline: String = ""
    @State private var authorName: String = ""
    @State private var useLogo: Bool = false
    @State private var logoFileName: String = ""
    @State private var logoImage: NSImage?
    @State private var accentColorRed: Double = 0.0
    @State private var accentColorGreen: Double = 0.478
    @State private var accentColorBlue: Double = 1.0
    @State private var blogTitle: String = ""
    @State private var blogTagline: String = ""
    @State private var homeHeroTitle: String = ""
    @State private var homeHeroSubtitle: String = ""
    @State private var homeCtaText: String = ""
    @State private var aboutTitle: String = ""
    @State private var aboutContent: String = ""
    @State private var portfolioTitle: String = ""
    @State private var portfolioTagline: String = ""
    @State private var showingSavedAlert = false
    
    var currentAppSettings: AppSettings? {
        return appSettings.first
    }
    
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
                        TextField("Site Name:", text: $siteName)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Tagline:", text: $tagline)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Author Name:", text: $authorName)
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
                                        Text(logoFileName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            Button("Change Logo...") {
                                                selectLogoImage()
                                            }
                                            
                                            Button("Remove Logo") {
                                                logoImage = nil
                                                logoFileName = ""
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
                        Toggle("Hide Company Name in Header", isOn: $useLogo)
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
                        TextField("Blog Title:", text: $blogTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Blog Tagline:", text: $blogTagline)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                }
                
                // MARK: - Home Page Settings
                GroupBox("Home Page") {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("Hero Title:", text: $homeHeroTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Hero Subtitle:", text: $homeHeroSubtitle)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Call-to-Action Button:", text: $homeCtaText)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                }
                
                // MARK: - About Page Settings
                GroupBox("About Page") {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("About Title:", text: $aboutTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("About Content:")
                            .font(.headline)
                        
                        TextEditor(text: $aboutContent)
                            .frame(height: 120)
                            .font(.system(.body, design: .default))
                            .border(Color.gray.opacity(0.3), width: 1)
                    }
                    .padding()
                }
                
                // MARK: - Portfolio Settings
                GroupBox("Portfolio") {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("Portfolio Title:", text: $portfolioTitle)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Portfolio Tagline:", text: $portfolioTagline)
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
            Text("Your settings have been saved. Restart the server to see changes.")
        }
    }
    
    // MARK: - Load Settings
    func loadSettings() {
        guard let settings = currentAppSettings else {
            // Create default settings if none exist
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            
            siteName = newSettings.siteName
            tagline = newSettings.siteTagline
            authorName = newSettings.authorName
            useLogo = newSettings.useLogo
            logoFileName = newSettings.logoFileName
            accentColorRed = newSettings.accentColorRed
            accentColorGreen = newSettings.accentColorGreen
            accentColorBlue = newSettings.accentColorBlue
            blogTitle = newSettings.blogTitle
            blogTagline = newSettings.blogTagline
            homeHeroTitle = newSettings.homeHeroTitle
            homeHeroSubtitle = newSettings.homeHeroSubtitle
            homeCtaText = newSettings.homeCtaText
            aboutTitle = newSettings.aboutTitle
            aboutContent = newSettings.aboutContent
            portfolioTitle = newSettings.portfolioTitle
            portfolioTagline = newSettings.portfolioTagline
            
            loadLogoImage()
            return
        }
        
        siteName = settings.siteName
        tagline = settings.siteTagline
        authorName = settings.authorName
        useLogo = settings.useLogo
        logoFileName = settings.logoFileName
        accentColorRed = settings.accentColorRed
        accentColorGreen = settings.accentColorGreen
        accentColorBlue = settings.accentColorBlue
        blogTitle = settings.blogTitle
        blogTagline = settings.blogTagline
        homeHeroTitle = settings.homeHeroTitle
        homeHeroSubtitle = settings.homeHeroSubtitle
        homeCtaText = settings.homeCtaText
        aboutTitle = settings.aboutTitle
        aboutContent = settings.aboutContent
        portfolioTitle = settings.portfolioTitle
        portfolioTagline = settings.portfolioTagline
        
        loadLogoImage()
    }
    
    // MARK: - Load Logo Image
    func loadLogoImage() {
        guard !logoFileName.isEmpty else {
            logoImage = nil
            // Restore default app icon when no logo
            NSApp.applicationIconImage = nil
            return
        }
        
        let imagesPath = (currentAppSettings?.outputDirectory as NSString?)?.expandingTildeInPath ?? ""
        let logoPath = (imagesPath as NSString).appendingPathComponent("images/\(logoFileName)")
        
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
        let panel = NSOpenPanel()
        panel.title = "Choose Logo Image"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.message = "Select an image to use as your site logo"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                copyLogoToSite(from: url)
            }
        }
    }
    
    // MARK: - Copy Logo to Site
    func copyLogoToSite(from sourceURL: URL) {
        guard let settings = currentAppSettings else { return }
        
        // Start accessing security-scoped resource
        guard sourceURL.startAccessingSecurityScopedResource() else {
            print("❌ Failed to access security-scoped resource")
            return
        }
        defer { sourceURL.stopAccessingSecurityScopedResource() }
        
        let imagesDir = (settings.outputDirectory as NSString).expandingTildeInPath + "/images"
        let fileName = "logo.\(sourceURL.pathExtension)"
        let destinationURL = URL(fileURLWithPath: (imagesDir as NSString).appendingPathComponent(fileName))
        
        do {
            // Ensure images directory exists
            try FileManager.default.createDirectory(atPath: imagesDir, withIntermediateDirectories: true)
            
            // Remove old logo if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy file
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            print("✅ Logo copied successfully to: \(destinationURL.path)")
            
            // Update state
            logoFileName = fileName
            logoImage = NSImage(contentsOf: destinationURL)
            
            // Set as app icon in Dock
            if let appIcon = logoImage {
                NSApp.applicationIconImage = appIcon
                print("✅ App icon updated in Dock")
            }
            
        } catch {
            print("❌ Error copying logo: \(error)")
        }
    }
    
    // MARK: - Save Settings
    func saveSettings() {
        guard let settings = currentAppSettings else { return }
        
        // Update all settings
        settings.siteName = siteName
        settings.siteTagline = tagline
        settings.authorName = authorName
        settings.useLogo = useLogo
        settings.logoFileName = logoFileName
        settings.accentColorRed = accentColorRed
        settings.accentColorGreen = accentColorGreen
        settings.accentColorBlue = accentColorBlue
        settings.blogTitle = blogTitle
        settings.blogTagline = blogTagline
        settings.homeHeroTitle = homeHeroTitle
        settings.homeHeroSubtitle = homeHeroSubtitle
        settings.homeCtaText = homeCtaText
        settings.aboutTitle = aboutTitle
        settings.aboutContent = aboutContent
        settings.portfolioTitle = portfolioTitle
        settings.portfolioTagline = portfolioTagline
        
        // Save to database
        try? modelContext.save()
        
        showingSavedAlert = true
    }
}

#Preview {
    CustomizeView()
        .modelContainer(for: [AppSettings.self, BlogPost.self])
}
