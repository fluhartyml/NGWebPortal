//
//  BlogEditorView.swift
//  NGWebPortal
//
//  Blog post editor with WYSIWYG rich text editing
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BlogEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BlogPost.publishedDate, order: .reverse) private var posts: [BlogPost]
    
    @State private var selectedPost: BlogPost?
    @State private var showingImagePicker = false
    @State private var showingPublishConfirmation = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationSplitView {
            // Post List
            List(selection: $selectedPost) {
                ForEach(posts) { post in
                    PostListItem(post: post)
                        .tag(post)
                }
            }
            .navigationTitle("Blog Posts")
            .toolbar {
                Button(action: createNewPost) {
                    Label("New Post", systemImage: "plus")
                }
            }
            
        } detail: {
            if let post = selectedPost {
                PostEditor(
                    post: post,
                    posts: posts,
                    showingImagePicker: $showingImagePicker,
                    showingPublishConfirmation: $showingPublishConfirmation,
                    showingDeleteConfirmation: $showingDeleteConfirmation
                )
            } else {
                Text("Select a post to edit or create a new one")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func createNewPost() {
        let newPost = BlogPost()
        modelContext.insert(newPost)
        try? modelContext.save()
        selectedPost = newPost
    }
}

struct PostListItem: View {
    let post: BlogPost
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageData = post.featuredImageData,
               let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title.isEmpty ? "Untitled Post" : post.title)
                    .font(.headline)
                
                if !post.subtitle.isEmpty {
                    Text(post.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if post.isDraft {
                        Label("Draft", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Label("Published", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Text(post.publishedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PostEditor: View {
    @Bindable var post: BlogPost
    let posts: [BlogPost]
    @Binding var showingImagePicker: Bool
    @Binding var showingPublishConfirmation: Bool
    @Binding var showingDeleteConfirmation: Bool
    
    @Environment(\.modelContext) private var modelContext
    @State private var contentAttributedString: NSAttributedString
    
    init(
        post: BlogPost,
        posts: [BlogPost],
        showingImagePicker: Binding<Bool>,
        showingPublishConfirmation: Binding<Bool>,
        showingDeleteConfirmation: Binding<Bool>
    ) {
        self.post = post
        self.posts = posts
        self._showingImagePicker = showingImagePicker
        self._showingPublishConfirmation = showingPublishConfirmation
        self._showingDeleteConfirmation = showingDeleteConfirmation
        
        // Initialize with existing content or empty string
        self._contentAttributedString = State(initialValue: NSAttributedString(string: post.content))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Featured Image
                if let imageData = post.featuredImageData,
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
                TextField("Post Title", text: $post.title)
                    .font(.largeTitle)
                    .textFieldStyle(.plain)
                
                // Subtitle
                TextField("Subtitle or brief synopsis", text: $post.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .textFieldStyle(.plain)
                
                Divider()
                
                // Rich Text Content Editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                    
                    RichTextEditorView(attributedText: $contentAttributedString)
                        .frame(minHeight: 400)
                        .onChange(of: contentAttributedString) { _, newValue in
                            // Convert attributed string to HTML for storage
                            post.content = attributedStringToHTML(newValue)
                        }
                }
                
                Divider()
                
                // Action Buttons
                HStack {
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
        .alert("Publish Post?", isPresented: $showingPublishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Publish") {
                publishPost()
            }
        } message: {
            Text("This will make your post visible on your website.")
        }
        .alert("Delete Post?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePost()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func removeImage() {
        post.featuredImageData = nil
        try? modelContext.save()
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result,
              let url = urls.first else {
            print("❌ Image selection failed or cancelled")
            return
        }
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Could not access security-scoped resource")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Load image data
        do {
            let imageData = try Data(contentsOf: url)
            print("✅ Image loaded: \(imageData.count) bytes")
            
            // Update the post's image data
            post.featuredImageData = imageData
            
            // Save to database
            try? modelContext.save()
            print("✅ Image saved to post")
            
        } catch {
            print("❌ Error loading image: \(error.localizedDescription)")
        }
    }
    
    private func saveDraft() {
        post.isDraft = true
        try? modelContext.save()
    }
    
    private func publishPost() {
        post.isDraft = false
        post.publishedDate = Date()
        try? modelContext.save()
        
        // Generate HTML file
        generateHTML()
        
        // Regenerate blog list index
        regenerateBlogIndex()
    }
    
    private func deletePost() {
        modelContext.delete(post)
        try? modelContext.save()
    }
    
    private func generateHTML() {
        let siteManager = SiteManager.shared
        
        // Get settings for accent color
        let html = generateBlogPostHTML()
        
        // Fix: Remove .html if it's already in the filename
        var cleanFilename = post.filename
        if cleanFilename.hasSuffix(".html") {
            cleanFilename = String(cleanFilename.dropLast(5))
        }
        let filename = "\(cleanFilename).html"
        
        siteManager.saveBlogPost(filename: filename, html: html)
        
        print("✅ Published: \(post.title)")
    }
    
    private func regenerateBlogIndex() {
        let siteManager = SiteManager.shared
        
        // Get all published posts
        let publishedPosts = posts.filter { !$0.isDraft }
        
        // Generate blog list HTML
        let blogListHTML = generateBlogListHTML(posts: publishedPosts)
        siteManager.saveBlogPost(filename: "index.html", html: blogListHTML)
        
        print("✅ Regenerated blog index with \(publishedPosts.count) posts")
    }
    
    private func generateBlogPostHTML() -> String {
        // TODO: Get actual site settings
        let siteName = "NG Web Portal"
        let siteTagline = "Welcome to my website"
        let accentColor = "#007AFF"
        
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
                    background: \(accentColor);
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
                    color: \(accentColor);
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
                
                .content h1, .content h2, .content h3 {
                    margin-top: 2rem;
                    margin-bottom: 1rem;
                }
                
                .content ul, .content ol {
                    margin-bottom: 1.5rem;
                    padding-left: 2rem;
                }
                
                .content a {
                    color: \(accentColor);
                    text-decoration: underline;
                }
                
                .back-link {
                    display: inline-block;
                    margin-top: 3rem;
                    color: \(accentColor);
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
    
    private func generateBlogListHTML(posts: [BlogPost]) -> String {
        let siteName = "NG Web Portal"
        let siteTagline = "Welcome to my website"
        let accentColor = "#007AFF"
        
        let postsHTML = posts.map { post in
            var imageHTML = ""
            if let imageData = post.featuredImageData {
                let base64String = imageData.base64EncodedString()
                imageHTML = """
                <img src="data:image/jpeg;base64,\(base64String)" alt="\(post.title)">
                """
            }
            
            // Fix filename for link
            var cleanFilename = post.filename
            if cleanFilename.hasSuffix(".html") {
                cleanFilename = String(cleanFilename.dropLast(5))
            }
            
            return """
            <article class="post-card">
                <div class="post-image">
                    \(imageHTML)
                </div>
                <div class="post-content">
                    <h2><a href="\(cleanFilename).html">\(post.title)</a></h2>
                    <p class="post-subtitle">\(post.subtitle)</p>
                    <a href="\(cleanFilename).html" class="read-more">Read More →</a>
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
                    background: \(accentColor);
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
                    color: \(accentColor);
                }
                
                .post-subtitle {
                    color: #666;
                    margin-bottom: 1rem;
                    font-size: 0.95rem;
                }
                
                .read-more {
                    color: \(accentColor);
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
    
    private func attributedStringToHTML(_ attributedString: NSAttributedString) -> String {
        // Convert NSAttributedString to HTML
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
    BlogEditorView()
        .modelContainer(for: BlogPost.self)
}

