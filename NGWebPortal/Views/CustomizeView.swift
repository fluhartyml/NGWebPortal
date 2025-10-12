//
//  CustomizeView.swift
//  NGWebPortal
//
//  Complete site customization interface
//

import SwiftUI
import SwiftData

struct CustomizeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var appSettings: [AppSettings]
    @Query private var allPosts: [BlogPost]
    
    private var currentSettings: AppSettings {
        if let settings = appSettings.first {
            return settings
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            return newSettings
        }
    }
    
    @State private var siteName: String = ""
    @State private var siteTagline: String = ""
    @State private var accentColor: Color = .blue
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case home = "Home Page"
        case blog = "Blog"
        case about = "About"
        case portfolio = "Portfolio"
    }
    
    var body: some View {
        HSplitView {
            // Sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: iconForTab(tab))
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180, idealWidth: 200)
            
            // Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    switch selectedTab {
                    case .general:
                        generalSettings
                    case .home:
                        homePageSettings
                    case .blog:
                        blogSettings
                    case .about:
                        aboutPageSettings
                    case .portfolio:
                        portfolioSettings
                    }
                }
                .padding(40)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - General Settings
    
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Settings")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Site Identity")
                    .font(.headline)
                
                TextField("Site Name", text: $siteName)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Site Tagline", text: $siteTagline)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Theme")
                    .font(.headline)
                
                ColorPicker("Accent Color", selection: $accentColor)
            }
            
            Spacer()
            
            HStack {
                Button("Save Changes") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Reset to Defaults") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Home Page Settings
    
    private var homePageSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Home Page")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            Text("Configure your home page layout and content")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Blog Settings
    
    private var blogSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Blog Settings")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            Text("Configure your blog appearance and behavior")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - About Page Settings
    
    private var aboutPageSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About Page")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            Text("Customize your about page")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Portfolio Settings
    
    private var portfolioSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Portfolio Settings")
                .font(.largeTitle)
                .bold()
            
            Divider()
            
            Text("Configure your portfolio display")
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Functions
    
    private func iconForTab(_ tab: SettingsTab) -> String {
        switch tab {
        case .general: return "gearshape"
        case .home: return "house"
        case .blog: return "doc.text"
        case .about: return "person"
        case .portfolio: return "folder"
        }
    }
    
    private func loadSettings() {
        let settings = currentSettings
        siteName = settings.siteName
        siteTagline = settings.siteTagline
        accentColor = Color(
            red: settings.accentColorRed,
            green: settings.accentColorGreen,
            blue: settings.accentColorBlue
        )
    }
    
    private func saveSettings() {
        let settings = currentSettings
        settings.siteName = siteName
        settings.siteTagline = siteTagline
        
        let components = accentColor.cgColor?.components ?? [0, 0, 0, 1]
        settings.accentColorRed = components[0]
        settings.accentColorGreen = components[1]
        settings.accentColorBlue = components[2]
        
        try? modelContext.save()
        
        // Regenerate entire site with new settings
        regenerateAllPages()
    }
    
    private func resetToDefaults() {
        siteName = "My Website"
        siteTagline = "Welcome to my site"
        accentColor = .blue
    }
    
    private func regenerateAllPages() {
        guard let siteFolder = SiteManager.shared.currentSiteFolder else {
            print("❌ Site folder not available")
            return
        }
        
        let fileManager = FileManager.default
        
        // Regenerate all blog posts with new accent color
        let blogFolder = siteFolder.appendingPathComponent("blog")
        do {
            try fileManager.createDirectory(at: blogFolder, withIntermediateDirectories: true)
        } catch {
            print("❌ Failed to create blog folder: \(error)")
            return
        }
        
        for post in allPosts where !post.isDraft {
            let html = generateBlogPostHTML(post: post)
            let filename = post.filename
            let postURL = blogFolder.appendingPathComponent("\(filename).html")
            do {
                try html.write(to: postURL, atomically: true, encoding: .utf8)
            } catch {
                print("❌ Failed to write blog post \(filename): \(error)")
            }
        }
        
        // Regenerate blog list page
        let blogListHTML = generateBlogListHTML()
        let blogListURL = siteFolder.appendingPathComponent("blog.html")
        do {
            try blogListHTML.write(to: blogListURL, atomically: true, encoding: .utf8)
        } catch {
            print("❌ Failed to write blog list: \(error)")
        }
        
        print("✅ Regenerated entire site with new settings")
    }
    
    private func generateBlogPostHTML(post: BlogPost) -> String {
        let accentHex = accentColor.toHex()
        
        var imageHTML = ""
        if let imageData = post.featuredImageData {
            let base64String = imageData.base64EncodedString()
            imageHTML = """
            <div class="featured-image">
                <img src="data:image/jpeg;base64,\(base64String)" alt="\(post.title)">
            </div>
            """
        }
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(post.title) - \(siteName)</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    background: #fff;
                }
                
                header {
                    background: \(accentHex);
                    color: white;
                    padding: 2rem;
                    text-align: center;
                }
                
                header h1 {
                    font-size: 2.5rem;
                    margin-bottom: 0.5rem;
                }
                
                nav {
                    display: flex;
                    gap: 2rem;
                    justify-content: center;
                    margin-top: 1rem;
                }
                
                nav a {
                    color: white;
                    text-decoration: none;
                    font-weight: 500;
                }
                
                nav a:hover {
                    text-decoration: underline;
                }
                
                .container {
                    max-width: 800px;
                    margin: 3rem auto;
                    padding: 0 2rem;
                }
                
                .featured-image {
                    margin-bottom: 2rem;
                    border-radius: 8px;
                    overflow: hidden;
                }
                
                .featured-image img {
                    width: 100%;
                    height: auto;
                    display: block;
                }
                
                h2 {
                    font-size: 2.5rem;
                    margin-bottom: 1rem;
                    color: \(accentHex);
                }
                
                .subtitle {
                    font-size: 1.25rem;
                    color: #666;
                    margin-bottom: 2rem;
                    font-style: italic;
                }
                
                .content {
                    font-size: 1.125rem;
                    line-height: 1.8;
                }
                
                .content p {
                    margin-bottom: 1.5rem;
                }
                
                .back-link {
                    display: inline-block;
                    margin-top: 3rem;
                    color: \(accentHex);
                    text-decoration: none;
                    font-weight: 500;
                }
                
                .back-link:hover {
                    text-decoration: underline;
                }
                
                footer {
                    text-align: center;
                    padding: 2rem;
                    background: #f5f5f5;
                    margin-top: 4rem;
                }
            </style>
        </head>
        <body>
            <header>
                <h1>\(siteName)</h1>
                <p>\(siteTagline)</p>
                <nav>
                    <a href="/index.html">Home</a>
                    <a href="/blog/index.html">Blog</a>
                    <a href="/about.html">About</a>
                    <a href="/portfolio.html">Portfolio</a>
                </nav>
            </header>
            <div class="container">
                \(imageHTML)
                <h2>\(post.title)</h2>
                <p class="subtitle">\(post.subtitle)</p>
                <div class="content">
                    \(post.content)
                </div>
                <a href="/blog/index.html" class="back-link">← Back to Blog</a>
            </div>
            <footer>
                <p>&copy; 2025 \(siteName). Powered by NG Web Portal</p>
            </footer>
        </body>
        </html>
        """
    }
    
    private func generateBlogListHTML() -> String {
        let accentHex = accentColor.toHex()
        let publishedPosts = allPosts.filter { !$0.isDraft }.sorted { $0.publishedDate > $1.publishedDate }
        
        let postsHTML = publishedPosts.map { post in
            var imageHTML = ""
            if let imageData = post.featuredImageData {
                let base64String = imageData.base64EncodedString()
                imageHTML = """
                <img src="data:image/jpeg;base64,\(base64String)" alt="\(post.title)">
                """
            }
            
            return """
            <article class="post-card">
                <div class="post-image">
                    \(imageHTML)
                </div>
                <div class="post-content">
                    <h2><a href="\(post.filename).html">\(post.title)</a></h2>
                    <p class="post-subtitle">\(post.subtitle)</p>
                    <a href="\(post.filename).html" class="read-more">Read More →</a>
                </div>
            </article>
            """
        }.joined(separator: "\n")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Blog - \(siteName)</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    background: #fff;
                }
                
                header {
                    background: \(accentHex);
                    color: white;
                    padding: 2rem;
                    text-align: center;
                }
                
                header h1 {
                    font-size: 2.5rem;
                    margin-bottom: 0.5rem;
                }
                
                nav {
                    display: flex;
                    gap: 2rem;
                    justify-content: center;
                    margin-top: 1rem;
                }
                
                nav a {
                    color: white;
                    text-decoration: none;
                    font-weight: 500;
                }
                
                nav a:hover {
                    text-decoration: underline;
                }
                
                .container {
                    max-width: 1200px;
                    margin: 3rem auto;
                    padding: 0 2rem;
                }
                
                .posts-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
                    gap: 2rem;
                }
                
                .post-card {
                    background: white;
                    border: 1px solid #e0e0e0;
                    border-radius: 8px;
                    overflow: hidden;
                    transition: transform 0.2s, box-shadow 0.2s;
                }
                
                .post-card:hover {
                    transform: translateY(-4px);
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                }
                
                .post-image {
                    width: 100%;
                    height: 200px;
                    overflow: hidden;
                    background: #f5f5f5;
                }
                
                .post-image img {
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }
                
                .post-content {
                    padding: 1.5rem;
                }
                
                .post-content h2 {
                    font-size: 1.5rem;
                    margin-bottom: 0.5rem;
                }
                
                .post-content h2 a {
                    color: #333;
                    text-decoration: none;
                }
                
                .post-content h2 a:hover {
                    color: \(accentHex);
                }
                
                .post-subtitle {
                    color: #666;
                    margin-bottom: 1rem;
                    font-size: 0.95rem;
                }
                
                .read-more {
                    color: \(accentHex);
                    text-decoration: none;
                    font-weight: 500;
                }
                
                .read-more:hover {
                    text-decoration: underline;
                }
                
                footer {
                    text-align: center;
                    padding: 2rem;
                    background: #f5f5f5;
                    margin-top: 4rem;
                }
            </style>
        </head>
        <body>
            <header>
                <h1>\(siteName)</h1>
                <p>\(siteTagline)</p>
                <nav>
                    <a href="/index.html">Home</a>
                    <a href="/blog/index.html">Blog</a>
                    <a href="/about.html">About</a>
                    <a href="/portfolio.html">Portfolio</a>
                </nav>
            </header>
            <div class="container">
                <div class="posts-grid">
                    \(postsHTML)
                </div>
            </div>
            <footer>
                <p>&copy; 2025 \(siteName). Powered by NG Web Portal</p>
            </footer>
        </body>
        </html>
        """
    }
}

extension Color {
    func toHex() -> String {
        let components = self.cgColor?.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

#Preview {
    CustomizeView()
        .modelContainer(for: [AppSettings.self, BlogPost.self])
}

