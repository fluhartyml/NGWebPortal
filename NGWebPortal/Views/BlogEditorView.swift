//
//  BlogEditorView.swift
//  NGWebPortal
//
//  Blog post creation and management interface
//

import SwiftUI
import SwiftData

struct BlogEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BlogPost.publishedDate, order: .reverse) private var posts: [BlogPost]
    
    @State private var selectedPost: BlogPost?
    @State private var isCreatingNew = false
    @State private var editTitle = ""
    @State private var editContent = ""
    @State private var editAuthor = ""
    @State private var editIsPublished = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HSplitView {
            // Left sidebar - post list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Blog Posts")
                        .font(.headline)
                        .padding()
                    Spacer()
                    Button(action: createNewPost) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing)
                }
                .background(Color.gray.opacity(0.1))
                
                List(selection: $selectedPost) {
                    ForEach(posts) { post in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.title)
                                .font(.headline)
                            HStack {
                                Text(post.formattedDate)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if post.isPublished {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                        }
                        .tag(post)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 200, idealWidth: 250)
            
            // Right side - post editor
            if let post = selectedPost {
                postEditorView(post: post)
            } else {
                VStack {
                    Text("Select a post to edit or create a new one")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: selectedPost) { oldValue, newValue in
            if let post = newValue {
                loadPostForEditing(post)
            }
        }
    }
    
    private func postEditorView(post: BlogPost) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                TextField("Post Title", text: $editTitle)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Author
            VStack(alignment: .leading, spacing: 8) {
                Text("Author")
                    .font(.headline)
                TextField("Author Name", text: $editAuthor)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Published toggle
            Toggle("Published", isOn: $editIsPublished)
                .toggleStyle(.switch)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.headline)
                
                RichTextEditor(html: $editContent)
                    .frame(maxHeight: .infinity)
                    .border(Color.gray.opacity(0.3), width: 1)
                    .cornerRadius(4)
            }
            
            // Action buttons
            HStack(spacing: 15) {
                Button("Save Changes") {
                    savePost(post)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Delete Post") {
                    showingDeleteAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Spacer()
                
                Text("Last updated: \(post.updatedAt.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Delete Post?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePost(post)
            }
        } message: {
            Text("Are you sure you want to delete \"\(post.title)\"? This cannot be undone.")
        }
    }
    
    private func createNewPost() {
        let newPost = BlogPost(
            title: "New Post",
            author: "Author"
        )
        modelContext.insert(newPost)
        try? modelContext.save()
        selectedPost = newPost
    }
    
    private func loadPostForEditing(_ post: BlogPost) {
        editTitle = post.title
        editContent = post.contentHTML
        editAuthor = post.author
        editIsPublished = post.isPublished
    }
    
    private func savePost(_ post: BlogPost) {
        post.title = editTitle
        post.contentHTML = editContent
        post.author = editAuthor
        post.isPublished = editIsPublished
        post.markUpdated()
        
        try? modelContext.save()
    }
    
    private func deletePost(_ post: BlogPost) {
        modelContext.delete(post)
        try? modelContext.save()
        selectedPost = nil
    }
}

#Preview {
    BlogEditorView()
        .modelContainer(for: BlogPost.self, inMemory: true)
}
