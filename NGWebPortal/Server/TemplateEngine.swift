//
//  TemplateEngine.swift
//  NGWebPortal
//
//  HTML template generation and blog publishing engine
//

import Foundation
import SwiftData
import AppKit

@MainActor
class TemplateEngine {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    private func getSettings() -> SiteSettings {
        return SettingsManager.shared.loadSettings()
    }
    
    // MARK: - Save Featured Image to Disk
    
    private func saveFeaturedImage(for post: BlogPost, to siteFolder: URL) -> String? {
        guard let imageData = post.featuredImageData else { return nil }
        
        // Create images directory if it doesn't exist
        let imagesFolder = siteFolder.appendingPathComponent("images")
        try? FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        
        // Generate unique filename based on post
        let imageFilename = "featured-\(post.id.uuidString).jpg"
        let imageURL = imagesFolder.appendingPathComponent(imageFilename)
        
        // Save image to disk
        do {
            try imageData.write(to: imageURL)
            return "images/\(imageFilename)"
        } catch {
            print("❌ Failed to save featured image: \(error)")
            return nil
        }
    }
    
    // MARK: - Blog List Page
    
    func generateBlogListHTML(posts: [BlogPost]) -> String {
        let settings = getSettings()
        let blogTitle = settings.blogTitle
        let blogTagline = settings.blogTagline
        
        let postsHTML = posts.map { post in
            let featuredImageHTML: String
            if let imagePath = post.featuredImageData != nil ? "images/featured-\(post.id.uuidString).jpg" : nil {
                featuredImageHTML = """
                <div class="post-thumbnail">
                    <img src="\(imagePath)" alt="\(post.title)">
                </div>
                """
            } else {
                featuredImageHTML = """
                <div class="post-thumbnail-placeholder">
                    <span>No Image</span>
                </div>
                """
            }
            
            // Create excerpt from subtitle or content
            let excerpt = !post.subtitle.isEmpty ? post.subtitle : String(post.content.prefix(200))
            
            // Generate slug from filename (remove .html extension)
            let slug = post.filename.replacingOccurrences(of: ".html", with: "")
            
            return """
            <article class="blog-post-preview">
                \(featuredImageHTML)
                <div class="post-content">
                    <h2><a href="blog/\(slug).html">\(post.title)</a></h2>
                    <div class="post-meta">
                        <time datetime="\(ISO8601DateFormatter().string(from: post.publishedDate))">
                            \(formatDate(post.publishedDate))
                        </time>
                    </div>
                    <p class="post-excerpt">\(excerpt)</p>
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
            <title>\(blogTitle)</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    background: #f5f5f5;
                }
                
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 40px 20px;
                }
                
                header {
                    text-align: center;
                    margin-bottom: 60px;
                }
                
                h1 {
                    font-size: 3em;
                    font-weight: 700;
                    margin-bottom: 10px;
                    color: #1a1a1a;
                }
                
                .tagline {
                    font-size: 1.2em;
                    color: #666;
                    font-weight: 300;
                }
                
                .blog-posts {
                    display: grid;
                    gap: 30px;
                }
                
                .blog-post-preview {
                    background: white;
                    border-radius: 12px;
                    overflow: hidden;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                    display: flex;
                    transition: transform 0.2s, box-shadow 0.2s;
                }
                
                .blog-post-preview:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 4px 16px rgba(0,0,0,0.15);
                }
                
                .post-thumbnail,
                .post-thumbnail-placeholder {
                    width: 300px;
                    flex-shrink: 0;
                    overflow: hidden;
                    background: #e0e0e0;
                    display: flex;
                    align-items: center;
                }
                
                .post-thumbnail img {
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }
                
                .post-thumbnail-placeholder {
                    justify-content: center;
                    color: #999;
                    font-size: 0.9em;
                }
                
                .post-content {
                    padding: 30px;
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                }
                
                .post-content h2 {
                    font-size: 1.8em;
                    margin-bottom: 10px;
                    line-height: 1.3;
                }
                
                .post-content h2 a {
                    color: #1a1a1a;
                    text-decoration: none;
                    transition: color 0.2s;
                }
                
                .post-content h2 a:hover {
                    color: #007AFF;
                }
                
                .post-meta {
                    color: #666;
                    font-size: 0.9em;
                    margin-bottom: 15px;
                }
                
                .post-excerpt {
                    color: #555;
                    line-height: 1.8;
                    flex: 1;
                }
                
                @media (max-width: 768px) {
                    .blog-post-preview {
                        flex-direction: column;
                    }
                    
                    .post-thumbnail,
                    .post-thumbnail-placeholder {
                        width: 100%;
                        height: 200px;
                    }
                    
                    h1 {
                        font-size: 2em;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <header>
                    <h1>\(blogTitle)</h1>
                    <p class="tagline">\(blogTagline)</p>
                </header>
                
                <div class="blog-posts">
                    \(postsHTML)
                </div>
            </div>
        </body>
        </html>
        """
    }
    
    // MARK: - Individual Blog Post
    
    func generateBlogPostHTML(post: BlogPost, allPosts: [BlogPost]) -> String {
        let settings = getSettings()
        let blogTitle = settings.blogTitle
        
        // Find previous and next posts
        let sortedPosts = allPosts.sorted { $0.publishedDate > $1.publishedDate }
        guard let currentIndex = sortedPosts.firstIndex(where: { $0.id == post.id }) else {
            return generateBlogPostHTML(post: post, previousPost: nil, nextPost: nil, blogTitle: blogTitle)
        }
        
        let previousPost = currentIndex > 0 ? sortedPosts[currentIndex - 1] : nil
        let nextPost = currentIndex < sortedPosts.count - 1 ? sortedPosts[currentIndex + 1] : nil
        
        return generateBlogPostHTML(post: post, previousPost: previousPost, nextPost: nextPost, blogTitle: blogTitle)
    }
    
    private func generateBlogPostHTML(post: BlogPost, previousPost: BlogPost?, nextPost: BlogPost?, blogTitle: String) -> String {
        let featuredImageHTML: String
        if post.featuredImageData != nil {
            let imagePath = "images/featured-\(post.id.uuidString).jpg"
            featuredImageHTML = """
            <div class="featured-image">
                <img src="../\(imagePath)" alt="\(post.title)">
            </div>
            """
        } else {
            featuredImageHTML = ""
        }
        
        let navigationHTML: String
        if previousPost != nil || nextPost != nil {
            let prevSlug = previousPost?.filename.replacingOccurrences(of: ".html", with: "") ?? ""
            let nextSlug = nextPost?.filename.replacingOccurrences(of: ".html", with: "") ?? ""
            
            let prevLink = previousPost.map { """
                <a href="\(prevSlug).html" class="nav-link prev">
                    <span class="nav-label">← Previous</span>
                    <span class="nav-title">\($0.title)</span>
                </a>
                """ } ?? "<div></div>"
            
            let nextLink = nextPost.map { """
                <a href="\(nextSlug).html" class="nav-link next">
                    <span class="nav-label">Next →</span>
                    <span class="nav-title">\($0.title)</span>
                </a>
                """ } ?? "<div></div>"
            
            navigationHTML = """
            <nav class="post-navigation">
                \(prevLink)
                \(nextLink)
            </nav>
            """
        } else {
            navigationHTML = ""
        }
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(post.title) - \(blogTitle)</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                    line-height: 1.8;
                    color: #333;
                    background: #f5f5f5;
                }
                
                .container {
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 40px 20px;
                }
                
                .back-link {
                    display: inline-flex;
                    align-items: center;
                    gap: 8px;
                    color: #007AFF;
                    text-decoration: none;
                    margin-bottom: 30px;
                    font-size: 0.95em;
                    padding: 8px 12px;
                    border-radius: 6px;
                    transition: background 0.2s;
                }
                
                .back-link:hover {
                    background: #f0f0f0;
                }
                
                .back-icon {
                    display: inline-flex;
                    align-items: center;
                    gap: 4px;
                }
                
                .back-icon svg {
                    width: 16px;
                    height: 16px;
                }
                
                article {
                    background: white;
                    border-radius: 12px;
                    padding: 60px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                }
                
                .featured-image {
                    margin: -60px -60px 40px -60px;
                    border-radius: 12px 12px 0 0;
                    overflow: hidden;
                }
                
                .featured-image img {
                    width: 100%;
                    height: auto;
                    display: block;
                }
                
                h1 {
                    font-size: 2.5em;
                    font-weight: 700;
                    margin-bottom: 20px;
                    line-height: 1.2;
                    color: #1a1a1a;
                }
                
                .post-meta {
                    color: #666;
                    font-size: 0.95em;
                    margin-bottom: 40px;
                    padding-bottom: 30px;
                    border-bottom: 1px solid #e0e0e0;
                }
                
                .post-content {
                    font-size: 1.1em;
                    line-height: 1.8;
                }
                
                .post-content p {
                    margin-bottom: 1.5em;
                }
                
                .post-navigation {
                    display: flex;
                    justify-content: space-between;
                    gap: 20px;
                    margin-top: 60px;
                    padding-top: 40px;
                    border-top: 1px solid #e0e0e0;
                }
                
                .nav-link {
                    display: flex;
                    flex-direction: column;
                    text-decoration: none;
                    color: #333;
                    padding: 20px;
                    background: #f8f8f8;
                    border-radius: 8px;
                    flex: 1;
                    transition: background 0.2s;
                }
                
                .nav-link:hover {
                    background: #e8e8e8;
                }
                
                .nav-link.prev {
                    align-items: flex-start;
                }
                
                .nav-link.next {
                    align-items: flex-end;
                    text-align: right;
                }
                
                .nav-label {
                    font-size: 0.85em;
                    color: #666;
                    margin-bottom: 5px;
                }
                
                .nav-title {
                    font-weight: 600;
                    color: #1a1a1a;
                }
                
                @media (max-width: 768px) {
                    article {
                        padding: 30px;
                    }
                    
                    .featured-image {
                        margin: -30px -30px 30px -30px;
                    }
                    
                    h1 {
                        font-size: 2em;
                    }
                    
                    .post-navigation {
                        flex-direction: column;
                    }
                    
                    .nav-link.next {
                        align-items: flex-start;
                        text-align: left;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <a href="../blog.html" class="back-link">
                    <span class="back-icon">
                        <svg viewBox="0 0 16 16" fill="currentColor">
                            <path d="M10 2L4 8l6 6"/>
                        </svg>
                        <svg viewBox="0 0 16 16" fill="currentColor">
                            <rect x="2" y="3" width="4" height="3" rx="1"/>
                            <rect x="2" y="7" width="8" height="1" rx="0.5"/>
                            <rect x="2" y="9" width="8" height="1" rx="0.5"/>
                            <rect x="2" y="11" width="8" height="1" rx="0.5"/>
                        </svg>
                    </span>
                    Back to List
                </a>
                
                <article>
                    \(featuredImageHTML)
                    
                    <h1>\(post.title)</h1>
                    
                    <div class="post-meta">
                        <time datetime="\(ISO8601DateFormatter().string(from: post.publishedDate))">
                            \(formatDate(post.publishedDate))
                        </time>
                    </div>
                    
                    <div class="post-content">
                        \(post.content)
                    </div>
                    
                    \(navigationHTML)
                </article>
            </div>
        </body>
        </html>
        """
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
