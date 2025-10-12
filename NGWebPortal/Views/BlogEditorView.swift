//
//  BlogEditorView.swift
//  NGWebPortal
//
//  Complete blog post editor with iWeb-inspired layout
//

import SwiftUI
import SwiftData
import PhotosUI

struct BlogEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BlogPost.publishedDate, order: .reverse) private var posts: [BlogPost]
    
    @State private var selectedPost: BlogPost?
    @State private var isCreatingNew = false
    @State private var isPublishingAll = false
    
    var body: some View {
        HSplitView {
            // Left sidebar - Post list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Blog Posts")
                        .font(.headline)
                    Spacer()
                    Button(action: publishAll) {
                        Image(systemName: "arrow.up.doc")
                        Text("Publish All")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(posts.isEmpty || isPublishingAll)
                    
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
                            .tag(post)
                    }
                    .listStyle(.sidebar)
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
    
    private func publishAll() {
        isPublishingAll = true
        Task {
            for post in posts {
                if let siteFolder = SiteManager.shared.currentSiteFolder {
                    do {
                        post.isDraft = false
                        if post.publishedDate < Date(timeIntervalSince1970: 0) {
                            post.publishedDate = Date()
                        }
                        try modelContext.save()
                        _ = try TemplateEngine.shared.generateBlogPostHTML(post: post, siteFolder: siteFolder)
                        print("✅ Published: \(post.title)")
                    } catch {
                        print("❌ Failed to publish \(post.title): \(error)")
                    }
                }
            }
            isPublishingAll = false
        }
    }
}

// MARK: - Post List Item
struct PostListItem: View {
    let post: BlogPost
    @Environment(\.modelContext) private var modelContext
    @State private var isPublishing = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail preview
            if let image = post.featuredImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.title2)
                    )
            }
            
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
            
            Spacer()
            
            // Publish button
            Button(action: { publishPost() }) {
                if isPublishing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "arrow.up.doc.fill")
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(.plain)
            .help("Publish this post")
            .disabled(isPublishing)
        }
        .padding(.vertical, 4)
    }
    
    private func publishPost() {
        guard let siteFolder = SiteManager.shared.currentSiteFolder else { return }
        
        isPublishing = true
        Task {
            do {
                post.isDraft = false
                if post.publishedDate < Date(timeIntervalSince1970: 0) {
                    post.publishedDate = Date()
                }
                try modelContext.save()
                _ = try TemplateEngine.shared.generateBlogPostHTML(post: post, siteFolder: siteFolder)
                print("✅ Published: \(post.title)")
            } catch {
                print("❌ Failed to publish: \(error)")
            }
            isPublishing = false
        }
    }
}

// MARK: - Post Editor Form
struct PostEditorForm: View {
    @Bindable var post: BlogPost
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPublishConfirmation = false
    @State private var showingPublishSuccess = false
    @State private var showingPublishError = false
    @State private var publishErrorMessage = ""
    
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
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
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
                        .onChange(of: selectedPhotoItem) { oldValue, newValue in
                            Task {
                                await loadSelectedPhoto()
                            }
                        }
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
        .alert("Publish Post?", isPresented: $showingPublishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Publish") {
                publishPost()
            }
        } message: {
            Text("This will make your post visible on your website.")
        }
        .alert("Published Successfully!", isPresented: $showingPublishSuccess) {
            Button("OK") { }
        } message: {
            Text("Your post is now live at:\nlocalhost:8080/blog/\(post.filename)")
        }
        .alert("Publish Failed", isPresented: $showingPublishError) {
            Button("OK") { }
        } message: {
            Text(publishErrorMessage)
        }
    }
    
    private func removeImage() {
        post.featuredImageData = nil
        selectedPhotoItem = nil
    }
    
    private func loadSelectedPhoto() async {
        guard let item = selectedPhotoItem else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    post.featuredImageData = data
                }
            }
        } catch {
            print("❌ Error loading photo: \(error)")
        }
    }
    
    private func saveDraft() {
        post.isDraft = true
        try? modelContext.save()
    }
    
    private func publishPost() {
        post.isDraft = false
        post.publishedDate = Date()
        
        do {
            try modelContext.save()
            try generateHTML()
            showingPublishSuccess = true
        } catch {
            publishErrorMessage = error.localizedDescription
            showingPublishError = true
        }
    }
    
    private func deletePost() {
        modelContext.delete(post)
        try? modelContext.save()
    }
    
    private func generateHTML() throws {
        // Get site folder from SiteManager
        guard let siteFolder = SiteManager.shared.currentSiteFolder else {
            throw NSError(domain: "BlogEditor", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Site folder not found. Please initialize site first."
            ])
        }
        
        // Generate HTML using TemplateEngine
        let postURL = try TemplateEngine.shared.generateBlogPostHTML(post: post, siteFolder: siteFolder)
        
        print("✅ Published: \(post.title)")
        print("📁 Location: \(postURL.path)")
        print("🌐 URL: http://localhost:8080/blog/\(post.filename)")
    }
}

#Preview {
    BlogEditorView()
        .modelContainer(for: BlogPost.self)
}
