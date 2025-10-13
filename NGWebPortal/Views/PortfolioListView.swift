//
//  PortfolioListView.swift
//  NGWebPortal
//
//  Portfolio project list and management view
//

import SwiftUI
import SwiftData

struct PortfolioListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [PortfolioProject]
    
    @State private var selectedProject: PortfolioProject?
    @State private var showingEditor = false
    
    var body: some View {
        NavigationSplitView {
            // Left sidebar - Project list
            List(selection: $selectedProject) {
                ForEach(projects) { project in
                    ProjectRow(project: project)
                        .tag(project)
                }
                .onDelete(perform: deleteProjects)
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: regeneratePortfolioIndex) {
                        Label("Refresh Portfolio", systemImage: "arrow.clockwise")
                    }
                    .help("Scan portfolio folder and regenerate index")
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: createNewProject) {
                        Label("New Project", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: publishAll) {
                        Label("Publish All", systemImage: "arrow.up.doc")
                    }
                    .disabled(projects.isEmpty)
                }
            }
        } detail: {
            // Right side - Editor or empty state
            if let project = selectedProject {
                PortfolioEditorView(project: project, allProjects: projects)
            } else {
                ContentUnavailableView(
                    "Select a project to edit or create a new one",
                    systemImage: "doc.text",
                    description: Text("Choose a project from the list or create a new one with the + button")
                )
            }
        }
    }
    
    private func createNewProject() {
        let newProject = PortfolioProject(
            title: "New Project",
            subtitle: "",
            projectDescription: "",
            technologies: "",
            projectURL: "",
            featuredImageData: nil,
            isDraft: true
        )
        modelContext.insert(newProject)
        try? modelContext.save()
        selectedProject = newProject
    }
    
    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            modelContext.delete(project)
            
            // Also delete the HTML file
            let siteManager = SiteManager.shared
            let filename = "\(project.slug).html"
            if let portfolioFolder = siteManager.currentSiteFolder?.appendingPathComponent("portfolio") {
                let filePath = portfolioFolder.appendingPathComponent(filename)
                try? FileManager.default.removeItem(at: filePath)
            }
        }
        try? modelContext.save()
        
        // Regenerate portfolio index
        regeneratePortfolioIndex()
    }
    
    private func publishAll() {
        let siteManager = SiteManager.shared
        
        // Publish all non-draft projects
        let publishedProjects = projects.filter { !$0.isDraft }
        
        for project in publishedProjects {
            let html = generateProjectHTML(for: project)
            let filename = "\(project.slug).html"
            siteManager.savePortfolioProject(filename: filename, html: html)
        }
        
        // Regenerate portfolio index
        regeneratePortfolioIndex()
        
        print("✅ Published \(publishedProjects.count) portfolio projects")
    }
    
    private func regeneratePortfolioIndex() {
        guard let siteFolder = SiteManager.shared.currentSiteFolder else {
            print("❌ Site folder not available")
            return
        }
        
        let portfolioFolder = siteFolder.appendingPathComponent("portfolio")
        
        // Scan filesystem for all files in portfolio folder
        guard let files = try? FileManager.default.contentsOfDirectory(at: portfolioFolder, includingPropertiesForKeys: [.isDirectoryKey]) else {
            print("❌ Failed to read portfolio folder")
            return
        }
        
        // Filter out index.html and directories
        let portfolioFiles = files.filter { url in
            !url.lastPathComponent.starts(with: ".") && // Skip hidden files
            url.lastPathComponent != "index.html" &&
            !url.hasDirectoryPath
        }
        
        print("✅ Found \(portfolioFiles.count) files in portfolio folder")
        
        // Parse each file to extract metadata
        var portfolioItems: [(title: String, subtitle: String, imageData: Data?, filename: String, isHTML: Bool)] = []
        
        for fileURL in portfolioFiles {
            let filename = fileURL.lastPathComponent
            
            if fileURL.pathExtension.lowercased() == "html" {
                // Parse HTML file for metadata
                if let htmlContent = try? String(contentsOf: fileURL, encoding: .utf8),
                   let title = extractTitle(from: htmlContent),
                   let subtitle = extractSubtitle(from: htmlContent) {
                    let imageData = extractFeaturedImage(from: htmlContent)
                    portfolioItems.append((title: title, subtitle: subtitle, imageData: imageData, filename: filename, isHTML: true))
                    print("  - HTML: \(title)")
                }
            } else {
                // Non-HTML file - just show filename
                let displayName = fileURL.deletingPathExtension().lastPathComponent
                portfolioItems.append((title: displayName, subtitle: "File: \(filename)", imageData: nil, filename: filename, isHTML: false))
                print("  - File: \(filename)")
            }
        }
        
        // Generate portfolio index HTML
        let portfolioListHTML = generatePortfolioListHTML(items: portfolioItems)
        SiteManager.shared.savePortfolioProject(filename: "index.html", html: portfolioListHTML)
        print("✅ Regenerated portfolio index with \(portfolioItems.count) items")
    }
    
    private func extractTitle(from html: String) -> String? {
        // Extract from <h2> tag
        if let range = html.range(of: "<h2>(.*?)</h2>", options: .regularExpression) {
            let h2Content = String(html[range])
            return h2Content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }
        return nil
    }
    
    private func extractSubtitle(from html: String) -> String? {
        // Extract from <p class="subtitle">
        if let range = html.range(of: "<p class=\"subtitle\">(.*?)</p>", options: .regularExpression) {
            let subtitle = String(html[range])
            return subtitle.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }
        return nil
    }
    
    private func extractFeaturedImage(from html: String) -> Data? {
        // Extract base64 image data
        if let range = html.range(of: "data:image/jpeg;base64,([A-Za-z0-9+/=]+)", options: .regularExpression) {
            let base64String = String(html[range]).replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
            return Data(base64Encoded: base64String)
        }
        return nil
    }
    
    private func generateProjectHTML(for project: PortfolioProject) -> String {
        let accentColor = "#007AFF"
        
        var imageHTML = ""
        if let imageData = project.featuredImageData {
            let base64String = imageData.base64EncodedString()
            imageHTML = """
            <div class="featured-image">
                <img src="data:image/jpeg;base64,\(base64String)" alt="\(project.title)">
            </div>
            """
        }
        
        var technologiesHTML = ""
        if !project.technologies.isEmpty {
            let techList = project.technologies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let techTags = techList.map { "<span class=\"tech-tag\">\($0)</span>" }.joined()
            technologiesHTML = """
            <div class="technologies">
                <h3>Technologies</h3>
                <div class="tech-tags">\(techTags)</div>
            </div>
            """
        }
        
        var projectLinkHTML = ""
        if !project.projectURL.isEmpty {
            projectLinkHTML = """
            <div class="project-link">
                <a href="\(project.projectURL)" target="_blank">View Project →</a>
            </div>
            """
        }
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(project.title) - NG Web Portal</title>
            <link rel="stylesheet" href="/css/style.css">
            <style>
                .header { background: \(accentColor); }
                .featured-image { margin: 2rem 0; }
                .featured-image img { max-width: 100%; height: auto; border-radius: 8px; }
                .tech-tags { display: flex; flex-wrap: wrap; gap: 0.5rem; margin-top: 1rem; }
                .tech-tag { background: \(accentColor); color: white; padding: 0.5rem 1rem; border-radius: 4px; font-size: 0.9rem; }
                .project-link { margin: 2rem 0; }
                .project-link a { background: \(accentColor); color: white; padding: 1rem 2rem; border-radius: 8px; text-decoration: none; display: inline-block; }
            </style>
        </head>
        <body>
            <div class="container">
                <header class="header">
                    <h1>NG Web Portal</h1>
                    <p>Portfolio</p>
                </header>
                
                <main>
                    <a href="/portfolio/" class="back-link">← Back to Portfolio</a>
                    
                    <article>
                        <h1>\(project.title)</h1>
                        \(imageHTML)
                        <div class="content">
                            \(project.projectDescription)
                        </div>
                        \(technologiesHTML)
                        \(projectLinkHTML)
                    </article>
                </main>
                
                <footer>
                    <p>&copy; 2025 NG Web Portal. All rights reserved.</p>
                </footer>
            </div>
        </body>
        </html>
        """
    }
    
    private func generatePortfolioListHTML(items: [(title: String, subtitle: String, imageData: Data?, filename: String, isHTML: Bool)]) -> String {
        let siteName = "NG Web Portal"
        let siteTagline = "Welcome to my website"
        let accentColor = "#007AFF"
        
        let projectsHTML = items.map { item in
            var imageHTML = ""
            if let imageData = item.imageData {
                let base64String = imageData.base64EncodedString()
                imageHTML = """
                <img src="data:image/jpeg;base64,\(base64String)" alt="\(item.title)">
                """
            } else if !item.isHTML {
                // Show file icon for non-HTML files
                imageHTML = """
                <div style="display: flex; align-items: center; justify-content: center; height: 100%; background: #f5f5f5;">
                    <svg width="80" height="80" viewBox="0 0 24 24" fill="none" stroke="#007AFF" stroke-width="2">
                        <path d="M13 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"></path>
                        <polyline points="13 2 13 9 20 9"></polyline>
                    </svg>
                </div>
                """
            }
            
            let href = item.isHTML ? item.filename : "/portfolio/\(item.filename)"
            let downloadAttr = item.isHTML ? "" : " download"
            
            return """
            <article class="project-card">
                <div class="project-image">\(imageHTML)</div>
                <div class="project-content">
                    <h2><a href="\(href)"\(downloadAttr)>\(item.title)</a></h2>
                    <p class="project-subtitle">\(item.subtitle)</p>
                    <a href="\(href)"\(downloadAttr) class="view-project">\(item.isHTML ? "View Project" : "Download") →</a>
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
            <title>Portfolio - \(siteName)</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; background: #fff; }
                header { background: \(accentColor); color: white; padding: 2rem; text-align: center; }
                header h1 { font-size: 2.5rem; margin-bottom: 0.5rem; }
                nav { display: flex; gap: 2rem; justify-content: center; margin-top: 1rem; }
                nav a { color: white; text-decoration: none; font-weight: 500; }
                nav a:hover { text-decoration: underline; }
                .container { max-width: 1200px; margin: 3rem auto; padding: 0 2rem; }
                .projects-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 2rem; }
                .project-card { background: white; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; transition: transform 0.2s, box-shadow 0.2s; }
                .project-card:hover { transform: translateY(-4px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
                .project-image { width: 100%; height: 200px; overflow: hidden; background: #f5f5f5; }
                .project-image img { width: 100%; height: 100%; object-fit: cover; }
                .project-content { padding: 1.5rem; }
                .project-content h2 { font-size: 1.5rem; margin-bottom: 0.5rem; }
                .project-content h2 a { color: #333; text-decoration: none; }
                .project-content h2 a:hover { color: \(accentColor); }
                .project-subtitle { color: #666; margin-bottom: 1rem; font-size: 0.95rem; }
                .view-project { color: \(accentColor); text-decoration: none; font-weight: 500; }
                .view-project:hover { text-decoration: underline; }
                footer { text-align: center; padding: 2rem; background: #f5f5f5; margin-top: 4rem; }
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
                    <a href="/portfolio/index.html">Portfolio</a>
                </nav>
            </header>
            <div class="container">
                <div class="projects-grid">
                    \(projectsHTML)
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

struct ProjectRow: View {
    let project: PortfolioProject
    
    var body: some View {
        HStack {
            if let imageData = project.featuredImageData,
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.headline)
                
                if !project.technologies.isEmpty {
                    Text(project.technologies)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if project.isDraft {
                        Text("Draft")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    } else {
                        Text("Published")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Text(project.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PortfolioListView()
        .modelContainer(for: PortfolioProject.self, inMemory: true)
}
