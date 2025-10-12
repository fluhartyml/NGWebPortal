//
//  PortfolioEditorView.swift
//  NGWebPortal
//
//  Portfolio project creation and management interface
//

import SwiftUI
import SwiftData
import AppKit

struct PortfolioEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PortfolioProject.displayOrder) private var projects: [PortfolioProject]
    
    @State private var selectedProject: PortfolioProject?
    @State private var editTitle = ""
    @State private var editDescription = ""
    @State private var editProjectURL = ""
    @State private var editDisplayOrder = 0
    @State private var editIsPublished = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HSplitView {
            // Left sidebar - project list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Portfolio Projects")
                        .font(.headline)
                        .padding()
                    Spacer()
                    Button(action: createNewProject) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing)
                }
                .background(Color.gray.opacity(0.1))
                
                List(selection: $selectedProject) {
                    ForEach(projects) { project in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.title)
                                .font(.headline)
                            HStack {
                                Text("Order: \(project.displayOrder)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if project.isPublished {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                        }
                        .tag(project)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 200, idealWidth: 250)
            
            // Right side - project editor
            if let project = selectedProject {
                projectEditorView(project: project)
            } else {
                VStack {
                    Text("Select a project to edit or create a new one")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: selectedProject) { oldValue, newValue in
            if let project = newValue {
                loadProjectForEditing(project)
            }
        }
    }
    
    private func projectEditorView(project: PortfolioProject) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Project Title")
                    .font(.headline)
                TextField("Project Title", text: $editTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Project URL
            VStack(alignment: .leading, spacing: 8) {
                Text("Project URL")
                    .font(.headline)
                TextField("https://example.com", text: $editProjectURL)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Display Order
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Order")
                    .font(.headline)
                HStack {
                    TextField("Order", value: $editDisplayOrder, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("(Lower numbers appear first)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Published toggle
            Toggle("Published", isOn: $editIsPublished)
                .toggleStyle(.switch)
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                
                TextEditor(text: $editDescription)
                    .frame(maxHeight: CGFloat.greatestFiniteMagnitude)
                    .border(Color.gray.opacity(0.3), width: 1)
                    .cornerRadius(4)
            }
            
            // Action buttons
            HStack(spacing: 15) {
                Button("Save Changes") {
                    saveProject(project)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Delete Project") {
                    showingDeleteAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Spacer()
                
                Text("Last updated: \(project.updatedAt.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Delete Project?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteProject(project)
            }
        } message: {
            Text("Are you sure you want to delete \"\(project.title)\"? This cannot be undone.")
        }
    }
    
    private func createNewProject() {
        let newProject = PortfolioProject(
            title: "New Project",
            displayOrder: projects.count
        )
        modelContext.insert(newProject)
        try? modelContext.save()
        selectedProject = newProject
    }
    
    private func loadProjectForEditing(_ project: PortfolioProject) {
        editTitle = project.title
        editDescription = project.descriptionHTML
        editProjectURL = project.projectURL
        editDisplayOrder = project.displayOrder
        editIsPublished = project.isPublished
    }
    
    private func saveProject(_ project: PortfolioProject) {
        project.title = editTitle
        project.descriptionHTML = editDescription
        project.projectURL = editProjectURL
        project.displayOrder = editDisplayOrder
        project.isPublished = editIsPublished
        project.markUpdated()
        
        try? modelContext.save()
    }
    
    private func deleteProject(_ project: PortfolioProject) {
        modelContext.delete(project)
        try? modelContext.save()
        selectedProject = nil
    }
}

#Preview {
    PortfolioEditorView()
        .modelContainer(for: PortfolioProject.self, inMemory: true)
}
