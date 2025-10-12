//
//  BlogEditorView.swift
//  NGWebPortal
//
//  Complete blog post editor with iWeb-inspired layout
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BlogEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BlogPost.publishedDate, order: .reverse) private var posts: [BlogPost]
    
    @State private var selectedPost: BlogPost?
    @State private var isCreatingNew = false
    
    var body: some View {
        HSplitView {
            // Left sidebar - Post list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Blog Posts")
                        .font(.headline)
                    Spacer()
                    Button(action: createNewPost) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                
                Divider()
                
                if posts.isEmpty {
                    VStack {
                        Spacer()
                        Text("No posts yet")
                            .foregroundStyle(.secondary)
                        Text("Click + to create your first post")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    List(posts, selection: $selectedPost) { post in
                        PostListItem(post: post)
                    }
                }
            }
            .frame(minWidth: 250, maxWidth: 300)
            
            // Right side - Post editor
            if let post = selectedPost {
                PostEditorForm(post: post)
            } else {
                VStack {
                    Spacer()
                    Text("Select a post to edit or create a new one")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func createNewPost() {
        let newPost = BlogPost()
        modelContext.insert(newPost)
        selectedPost = newPost
    }
}

// MARK: - Post List Item
struct PostListItem: View {
    let post: BlogPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.title.isEmpty ? "Untitled Post" : post.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(post.subtitle.isEmpty ? "No subtitle" : post.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            HStack {
                if post.isDraft {
                    Text("Draft")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
                
                Text(post.publishedDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Post Editor Form
struct PostEditorForm: View {
    @Bindable var post: BlogPost
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingImagePicker = false
    @State private var showingPublishConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Featured Image Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Featured Image")
                        .font(.headline)
                    
                    if let image = post.featuredImage {
                        ZStack(alignment: .topTrailing) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(8)
                            
                            Button(action: removeImage) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .buttonStyle(.plain)
                            .padding(8)
                        }
                    } else {
                        Button(action: { showingImagePicker = true }) {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("Choose Featured Image")
                                    .font(.headline)
                                Text("This image will inspire your post")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.headline)
                    TextField("Enter your blog post title...", text: $post.title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 28, weight: .bold))
                }
                
                // Subtitle/Synopsis
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subtitle / Synopsis")
                        .font(.headline)
                    TextField("Brief introduction or synopsis...", text: $post.subtitle)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                    
                    TextEditor(text: $post.content)
                        .font(.system(size: 16))
                        .frame(minHeight: 400)
                        .scrollContentBackground(.hidden)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                }
                
                Divider()
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button("Delete Post") {
                        deletePost()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Spacer()
                    
                    if post.isDraft {
                        Button("Save Draft") {
                            saveDraft()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(post.isDraft ? "Publish" : "Update") {
                        showingPublishConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(post.title.isEmpty)
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
        .alert("Publish Post?", isPresented: $showingPublishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Publish") {
                publishPost()
            }
        } message: {
            Text("This will make your post visible on your website.")
        }
    }
    
    private func removeImage() {
        post.featuredImageData = nil
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result,
              let url = urls.first,
              let imageData = try? Data(contentsOf: url) else {
            return
        }
        post.featuredImageData = imageData
    }
    
    private func saveDraft() {
        post.isDraft = true
        try? modelContext.save()
    }
    
    private func publishPost() {
        post.isDraft = false
        post.publishedDate = Date()
        try? modelContext.save()
        
        // TODO: Generate HTML file
        generateHTML()
    }
    
    private func deletePost() {
        modelContext.delete(post)
        try? modelContext.save()
    }
    
    private func generateHTML() {
        // TODO: Implement HTML generation using TemplateEngine
        print("📝 Generating HTML for: \(post.title)")
        print("📁 Filename: \(post.filename)")
    }
}

#Preview {
    BlogEditorView()
        .modelContainer(for: BlogPost.self)
}
