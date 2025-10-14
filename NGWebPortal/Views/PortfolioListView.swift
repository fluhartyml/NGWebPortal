//
//  PortfolioListView.swift
//  NGWebPortal
//
//  Portfolio project list and management
//
//  ⏰ ARTIFACT GENERATED: 2025 OCT 13 19:50
//  🔑 VERSION: TIMESTAMPED-FRESH

import SwiftUI
import SwiftData

struct PortfolioListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PortfolioProject.title, order: .forward) private var projects: [PortfolioProject]
    
    @State private var selection: PortfolioProject?
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(projects) { project in
                    NavigationLink(value: project) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.title.isEmpty ? "Untitled Project" : project.title)
                                .font(.headline)
                            if !project.subtitle.isEmpty {
                                Text(project.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: add) {
                        Label("New Project", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let project = selection {
                PortfolioEditorView(project: project, allProjects: projects)
            } else {
                ContentUnavailableView("Select a Project", systemImage: "folder", description: Text("Choose an existing project or create a new one."))
            }
        }
    }
    
    private func add() {
        let new = PortfolioProject(title: "New Project", subtitle: "", projectDescription: "", technologies: "", projectURL: "")
        modelContext.insert(new)
        selection = new
    }
    
    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(projects[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: PortfolioProject.self, configurations: config)
    return PortfolioListView()
        .modelContainer(container)
}
