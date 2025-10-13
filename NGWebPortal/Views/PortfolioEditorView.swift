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
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                } else {
                    Button(action: { showingImagePicker = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Add Featured Image")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                
                // Project Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Title")
                        .font(.headline)
                    TextField("Enter project title", text: $project.title)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Subtitle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subtitle")
                        .font(.headline)
                    TextField("Brief tagline for this project", text: $project.subtitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Technologies
                VStack(alignment: .leading, spacing: 8) {
                    Text("Technologies")
                        .font(.headline)
                    TextField("e.g., Swift, SwiftUI, Node.js", text: $project.technologies)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Project URL
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project URL")
                        .font(.headline)
                    TextField("https://", text: $project.projectURL)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Project Description with Rich Text Editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Description")
                        .font(.headline)
                    
                    RichTextEditorView(attributedText: $descriptionAttributedString)
                        .frame(minHeight: 300)
                        .onChange(of: descriptionAttributedString) { _, newValue in
                            project.projectDescription = newValue.string
                        }
                }
                
                Divider()
                
                // Draft Status
                Toggle("Draft (not published)", isOn: $project.isDraft)
                
                Divider()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Publish Project") {
                        showingPublishConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(project.title.isEmpty)
                    
                    Button("Delete Project") {
                        showingDeleteConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
        .navigationTitle(project.title.isEmpty ? "New Project" : project.title)
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImageSelection(result)
        }
        .alert("Publish Project", isPresented: $showingPublishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Publish") {
                publishProject()
            }
        } message: {
            Text("This will regenerate the portfolio page with this project.")
        }
        .alert("Delete Project", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProject()
            }
        } message: {
            Text("Are you sure you want to delete this project? This cannot be undone.")
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                
                if let imageData = try? Data(contentsOf: url) {
                    project.featuredImageData = imageData
                }
            }
            
        case .failure(let error):
            print("Error selecting image: \(error.localizedDescription)")
        }
    }
    
    private func removeImage() {
        project.featuredImageData = nil
    }
    
    private func publishProject() {
        project.isDraft = false
        
        do {
            try modelContext.save()
            print("✅ Project published: \(project.title)")
        } catch {
            print("❌ Error publishing project: \(error.localizedDescription)")
        }
    }
    
    private func deleteProject() {
        modelContext.delete(project)
        
        do {
            try modelContext.save()
            print("✅ Project deleted")
        } catch {
            print("❌ Error deleting project: \(error.localizedDescription)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PortfolioProject.self, configurations: config)
    
    let project = PortfolioProject(
        title: "Sample Project",
        subtitle: "A test project",
        projectDescription: "Test description",
        technologies: "Swift, SwiftUI",
        projectURL: "https://example.com"
    )
    
    return PortfolioEditorView(project: project, allProjects: [project])
        .modelContainer(container)
}
