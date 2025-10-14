//
//  PortfolioListView.swift
//  NGWebPortal
//
//  Portfolio project list and management
//
//  ⏰ ARTIFACT GENERATED: 2025 OCT 13 20:18
//  🔑 VERSION: TIMESTAMPED-FRESH

import SwiftUI
import SwiftData

struct PortfolioListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PortfolioProject.title, order: .forward) private var projects: [PortfolioProject]
    
    @State private var selection: PortfolioProject?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Project List
            List(selection: $selection) {
                ForEach(projects) { project in
                    HStack(spacing: 12) {
                        // Thumbnail
                        if let imageData = project.featuredImageData,
                           let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundStyle(.gray)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.title.isEmpty ? "Untitled Project" : project.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if !project.subtitle.isEmpty {
                                Text(project.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            
                            // Draft badge
                            if project.isDraft {
                                Text("DRAFT")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .tag(project)
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: refreshFromFolder) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .help("Scan portfolio folder for HTML files")
                    .disabled(isRefreshing)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: add) {
                        Label("New Project", systemImage: "plus")
                    }
                }
            }
        } detail: {
            // Detail - Editor
            if let project = selection {
                PortfolioEditorView(project: project, allProjects: projects)
            } else {
                ContentUnavailableView(
                    "Select a Project",
                    systemImage: "folder",
                    description: Text("Choose an existing project or create a new one.")
                )
            }
        }
    }
    
    private func add() {
        let new = PortfolioProject(
            title: "New Project",
            subtitle: "",
            projectDescription: "",
            technologies: "",
            projectURL: ""
        )
        modelContext.insert(new)
        selection = new
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(projects[index])
        }
        try? modelContext.save()
    }
    
    private func refreshFromFolder() {
        isRefreshing = true
        
        guard let siteFolder = SiteManager.shared.currentSiteFolder else {
            isRefreshing = false
            return
        }
        
        let portfolioFolder = siteFolder.appendingPathComponent("portfolio")
        
        // Create portfolio folder if it doesn't exist
        if !FileManager.default.fileExists(atPath: portfolioFolder.path) {
            try? FileManager.default.createDirectory(at: portfolioFolder, withIntermediateDirectories: true)
            isRefreshing = false
            return
        }
        
        // Get all HTML files in portfolio folder
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: portfolioFolder,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            isRefreshing = false
            return
        }
        
        // Filter for HTML files (excluding index.html)
        let htmlFiles = files.filter {
            $0.pathExtension.lowercased() == "html" &&
            $0.lastPathComponent != "index.html"
        }
        
        // Check which files are NOT already in database
        let existingSlugs = projects.map { $0.slug }
        
        for fileURL in htmlFiles {
            let filename = fileURL.deletingPathExtension().lastPathComponent
            
            // Skip if already in database
            guard !existingSlugs.contains(filename) else { continue }
            
            // Look for associated image file
            var imageData: Data?
            let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp"]
            
            for ext in imageExtensions {
                let imageURL = portfolioFolder.appendingPathComponent("\(filename).\(ext)")
                if FileManager.default.fileExists(atPath: imageURL.path),
                   let data = try? Data(contentsOf: imageURL) {
                    imageData = data
                    break
                }
            }
            
            // Import as new project
            // Note: We set the title such that when slug is computed, it matches the filename
            let imported = PortfolioProject(
                title: filename.replacingOccurrences(of: "-", with: " ").capitalized,
                subtitle: "Imported from HTML",
                projectDescription: "This project was imported from an existing HTML file.",
                technologies: "",
                projectURL: "",
                featuredImageData: imageData,
                isDraft: false
            )
            
            modelContext.insert(imported)
        }
        
        try? modelContext.save()
        
        isRefreshing = false
        print("✅ Refreshed from folder: imported \(htmlFiles.count - existingSlugs.count) new projects")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PortfolioProject.self, configurations: config)
    return PortfolioListView()
        .modelContainer(container)
}
