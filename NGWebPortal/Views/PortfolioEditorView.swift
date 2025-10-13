//
//  PortfolioEditorView.swift
//  NGWebPortal
//
//  Portfolio project editor with WYSIWYG rich text editing
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct PortfolioEditorView: View {
    @Bindable var project: PortfolioProject
    @Environment(\.modelContext) private var modelContext
    
    let allProjects: [PortfolioProject]
    
    @State private var showingImagePicker = false
    @State private var showingPublishConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var descriptionAttributedString: NSAttributedString
    
    init(project: PortfolioProject, allProjects: [PortfolioProject]) {
        self.project = project
        self.allProjects = allProjects
        self._descriptionAttributedString = State(initialValue: NSAttributedString(string: project.projectDescription))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Featured Image
                if let imageData = project.featuredImageData,
                   let nsImage = NSImage(data: imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button(action: removeImage) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(8)
                        .buttonStyle(.plain)
                    }
                } else {
                    Button(action: { showingImagePicker = true }) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay {
                                VStack {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("Add Featured Image")
                                        .foregroundColor(.secondary)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
                
                // Title
                TextField("Project Title", text: $project.title)
                    .font(.largeTitle)
                    .textFieldStyle(.plain)
                
                // Subtitle
                TextField("Brief project description", text: $project.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .textFieldStyle(.plain)
                
                // Project URL
                TextField("Project URL (optional)", text: $project.projectURL)
                    .font(.body)
                    .textFieldStyle(.plain)
                
                // Technologies
                TextField("Technologies used (e.g., Swift, SwiftUI)", text: $project.technologies)
                    .font(.body)
                    .textFieldStyle(.plain)
                
                Divider()
                
                // Rich Text Description Editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Description")
                        .font(.headline)
                    
                    RichTextEditorView(attributedText: $descriptionAttributedString)
                        .frame(minHeight: 400)
                        .onChange(of: descriptionAttributedString) { _, newValue in
                            project.projectDescription = attributedStringToHTML(newValue)
                        }
                }
                
                Divider()
                
                // Action Buttons
                HStack {
                    if project.isDraft {
                        Button("Save Draft") {
                            saveDraft()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(project.isDraft ? "Publish" : "Update") {
                        showingPublishConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(project.title.isEmpty)
                    
                    Spacer()
                    
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical)
            }
            .padding(40)
        }
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImageSelection(result)
        }
        .alert("Publish Project?", isPresented: $showingPublishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Publish") {
                publishProject()
            }
        } message: {
            Text("This will make your project visible on your website.")
        }
        .alert("Delete Project?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProject()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func removeImage() {
        project.featuredImageData = nil
        try? modelContext.save()
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result,
              let url = urls.first else {
            print("❌ Image selection failed or cancelled")
            return
        }
        
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Could not access security-scoped resource")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let imageData = try Data(contentsOf: url)
            print("✅ Image loaded: \(imageData.count) bytes")
            project.featuredImageData = imageData
            try? modelContext.save()
            print("✅ Image saved to project")
        } catch {
            print("❌ Error loading image: \(error.localizedDescription)")
        }
    }
    
    private func saveDraft() {
        project.isDraft = true
        try? modelContext.save()
    }
    
    private func publishProject() {
        project.isDraft = false
        
        // Save and wait for SwiftData to commit before regenerating index
        do {
            try modelContext.save()
            print("✅ Project saved with isDraft = false")
            
            // Give SwiftData a moment to commit the transaction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.generateHTML()
                self.regeneratePortfolioIndex()
            }
        } catch {
            print("❌ Failed to save project: \(error)")
        }
    }
    
    private func deleteProject() {
        modelContext.delete(project)
        try? modelContext.save()
    }
    
    private func generateHTML() {
        let siteManager = SiteManager.shared
        let html = generateProjectHTML()
        
        var cleanFilename = project.slug
        if cleanFilename.hasSuffix(".html") {
            cleanFilename = String(cleanFilename.dropLast(5))
        }
        let filename = "\(cleanFilename).html"
        
        siteManager.savePortfolioProject(filename: filename, html: html)
        print("✅ Published: \(project.title)")
    }
    
    private func regeneratePortfolioIndex() {
        let siteManager = SiteManager.shared
        
        // Query SwiftData directly for all published projects (fixes stale array bug)
        let descriptor = FetchDescriptor<PortfolioProject>(
            predicate: #Predicate { !$0.isDraft },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        guard let publishedProjects = try? modelContext.fetch(descriptor) else {
            print("❌ Failed to fetch published projects")
            return
        }
        
        print("✅ Found \(publishedProjects.count) published projects:")
        for proj in publishedProjects {
            print("  - \(proj.title) (isDraft: \(proj.isDraft))")
        }
        
        let portfolioListHTML = generatePortfolioListHTML(projects: publishedProjects)
        siteManager.savePortfolioProject(filename: "index.html", html: portfolioListHTML)
        print("✅ Regenerated portfolio index with \(publishedProjects.count) projects")
    }
    
    private func generateProjectHTML() -> String {
        let siteName = "NG Web Portal"
        let siteTagline = "Welcome to my website"
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
            let techTags = techList.map { "<span class=\"tech-tag\">\($0)</span>" }.joined(separator: " ")
            technologiesHTML = """
            <div class="technologies">
                <strong>Technologies:</strong> \(techTags)
            </div>
            """
        }
        
        var projectLinkHTML = ""
        if !project.projectURL.isEmpty {
            projectLinkHTML = """
            <div class="project-link">
                <a href="\(project.projectURL)" target="_blank" rel="noopener">View Project →</a>
            </div>
            """
        }
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(project.title) - \(siteName)</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; color: #333; background: #fff; }
                header { background: \(accentColor); color: white; padding: 2rem; text-align: center; }
                header h1 { font-size: 2.5rem; margin-bottom: 0.5rem; }
                nav { display: flex; gap: 2rem; justify-content: center; margin-top: 1rem; }
                nav a { color: white; text-decoration: none; font-weight: 500; }
                nav a:hover { text-decoration: underline; }
                .container { max-width: 800px; margin: 3rem auto; padding: 0 2rem; }
                .featured-image { margin-bottom: 2rem; border-radius: 8px; overflow: hidden; }
                .featured-image img { width: 100%; height: auto; display: block; }
                h2 { font-size: 2.5rem; margin-bottom: 1rem; color: \(accentColor); }
                .subtitle { font-size: 1.25rem; color: #666; margin-bottom: 1rem; font-style: italic; }
                .technologies { margin-bottom: 2rem; padding: 1rem; background: #f5f5f5; border-radius: 8px; }
                .tech-tag { display: inline-block; padding: 0.25rem 0.75rem; margin: 0.25rem; background: white; border: 1px solid #ddd; border-radius: 4px; font-size: 0.9rem; }
                .project-link { margin: 2rem 0; }
                .project-link a { display: inline-block; padding: 0.75rem 1.5rem; background: \(accentColor); color: white; text-decoration: none; border-radius: 4px; font-weight: 500; }
                .project-link a:hover { opacity: 0.9; }
                .description { font-size: 1.125rem; line-height: 1.8; }
                .description p { margin-bottom: 1.5rem; }
                .description h1, .description h2, .description h3 { margin-top: 2rem; margin-bottom: 1rem; }
                .description ul, .description ol { margin-bottom: 1.5rem; padding-left: 2rem; }
                .description a { color: \(accentColor); text-decoration: underline; }
                .back-link { display: inline-block; margin-top: 3rem; color: \(accentColor); text-decoration: none; font-weight: 500; }
                .back-link:hover { text-decoration: underline; }
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
                    <a href="/portfolio.html">Portfolio</a>
                </nav>
            </header>
            <div class="container">
                \(imageHTML)
                <h2>\(project.title)</h2>
                <p class="subtitle">\(project.subtitle)</p>
                \(technologiesHTML)
                \(projectLinkHTML)
                <div class="description">
                    \(project.projectDescription)
                </div>
                <a href="/portfolio.html" class="back-link">← Back to Portfolio</a>
            </div>
            <footer>
                <p>&copy; 2025 \(siteName). Powered by NG Web Portal</p>
            </footer>
        </body>
        </html>
        """
    }
    
    private func generatePortfolioListHTML(projects: [PortfolioProject]) -> String {
        let siteName = "NG Web Portal"
        let siteTagline = "Welcome to my website"
        let accentColor = "#007AFF"
        
        let projectsHTML = projects.map { project in
            var imageHTML = ""
            if let imageData = project.featuredImageData {
                let base64String = imageData.base64EncodedString()
                imageHTML = """
                <img src="data:image/jpeg;base64,\(base64String)" alt="\(project.title)">
                """
            }
            
            var cleanFilename = project.slug
            if cleanFilename.hasSuffix(".html") {
                cleanFilename = String(cleanFilename.dropLast(5))
            }
            
            return """
            <article class="project-card">
                <div class="project-image">\(imageHTML)</div>
                <div class="project-content">
                    <h2><a href="\(cleanFilename).html">\(project.title)</a></h2>
                    <p class="project-subtitle">\(project.subtitle)</p>
                    <a href="\(cleanFilename).html" class="view-project">View Project →</a>
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
                    <a href="/portfolio.html">Portfolio</a>
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
    
    private func attributedStringToHTML(_ attributedString: NSAttributedString) -> String {
        let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let htmlData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: documentAttributes
        ),
              let htmlString = String(data: htmlData, encoding: .utf8) else {
            return attributedString.string
        }
        
        return htmlString
    }
}

#Preview {
    PortfolioEditorView(
        project: PortfolioProject(),
        allProjects: []
    )
    .modelContainer(for: PortfolioProject.self, inMemory: true)
}
