//
//  TemplateEngine.swift
//  NGWebPortal
//
//  HTML template generation for blog posts and pages
//

import Foundation
import AppKit

class TemplateEngine {
    
    static let shared = TemplateEngine()
    
    private init() {}
    
    // MARK: - Blog Post Generation
    
    func generateBlogPostHTML(post: BlogPost, siteFolder: URL) throws -> URL {
        // Create blog directory if needed
        let blogFolder = siteFolder.appendingPathComponent("blog")
        try FileManager.default.createDirectory(at: blogFolder, withIntermediateDirectories: true)
        
        // Create images directory if needed
        let imagesFolder = siteFolder.appendingPathComponent("images")
        try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        
        // Handle featured image
        var imagePath = ""
        if let imageData = post.featuredImageData {
            let imageFilename = "featured-\(post.id.uuidString).jpg"
            let imageURL = imagesFolder.appendingPathComponent(imageFilename)
            try imageData.write(to: imageURL)
            imagePath = "../images/\(imageFilename)"
        }
        
        // Generate HTML content
        let html = generatePostHTML(post: post, imagePath: imagePath)
        
        // Write to file
        let postURL = blogFolder.appendingPathComponent(post.filename)
        try html.write(to: postURL, atomically: true, encoding: .utf8)
        
        // Update blog index
        try updateBlogIndex(siteFolder: siteFolder)
        
        return postURL
    }
    
    private func generatePostHTML(post: BlogPost, imagePath: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        let dateString = dateFormatter.string(from: post.publishedDate)
        
        let featuredImageHTML = imagePath.isEmpty ? "" : """
        <div class="featured-image">
            <img src="\(imagePath)" alt="\(escapeHTML(post.title))">
        </div>
        """
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(escapeHTML(post.title)) - NightGard Blog</title>
            <link rel="stylesheet" href="../styles.css">
            <style>
                .blog-post {
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 40px 20px;
                }
                
                .featured-image {
                    width: 100%;
                    margin-bottom: 40px;
                    border-radius: 8px;
                    overflow: hidden;
                }
                
                .featured-image img {
                    width: 100%;
                    height: auto;
                    display: block;
                }
                
                .post-header {
                    margin-bottom: 40px;
                }
                
                .post-title {
                    font-size: 48px;
                    font-weight: bold;
                    margin-bottom: 16px;
                    line-height: 1.2;
                }
                
                .post-subtitle {
                    font-size: 24px;
                    color: #666;
                    margin-bottom: 24px;
                    line-height: 1.4;
                }
                
                .post-meta {
                    color: #999;
                    font-size: 14px;
                    margin-bottom: 40px;
                    padding-bottom: 20px;
                    border-bottom: 1px solid #eee;
                }
                
                .post-content {
                    font-size: 18px;
                    line-height: 1.8;
                    color: #333;
                }
                
                .post-content p {
                    margin-bottom: 20px;
                }
                
                .back-link {
                    display: inline-block;
                    margin-top: 40px;
                    padding: 10px 20px;
                    background: #007AFF;
                    color: white;
                    text-decoration: none;
                    border-radius: 6px;
                }
                
                .back-link:hover {
                    background: #0051D5;
                }
            </style>
        </head>
        <body>
            <div class="blog-post">
                \(featuredImageHTML)
                
                <div class="post-header">
                    <h1 class="post-title">\(escapeHTML(post.title))</h1>
                    <p class="post-subtitle">\(escapeHTML(post.subtitle))</p>
                    <div class="post-meta">
                        By \(escapeHTML(post.author)) • \(dateString)
                    </div>
                </div>
                
                <div class="post-content">
                    \(formatContent(post.content))
                </div>
                
                <a href="index.html" class="back-link">← Back to Blog</a>
            </div>
        </body>
        </html>
        """
    }
    
    // MARK: - Blog Index Generation
    
    func updateBlogIndex(siteFolder: URL) throws {
        let blogFolder = siteFolder.appendingPathComponent("blog")
        
        // Read all blog posts from the blog folder
        let fileManager = FileManager.default
        let blogFiles = try fileManager.contentsOfDirectory(at: blogFolder, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "html" && $0.lastPathComponent != "index.html" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
        
        let html = generateBlogIndexHTML(postFiles: blogFiles)
        let indexURL = blogFolder.appendingPathComponent("index.html")
        try html.write(to: indexURL, atomically: true, encoding: .utf8)
    }
    
    private func generateBlogIndexHTML(postFiles: [URL]) -> String {
        let postListHTML = postFiles.isEmpty ? """
        <div class="no-posts">
            <p>No posts yet. Check back soon!</p>
        </div>
        """ : postFiles.map { url in
            let filename = url.lastPathComponent
            let title = filename.replacingOccurrences(of: ".html", with: "")
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
            
            return """
            <div class="post-preview">
                <h2><a href="\(filename)">\(title)</a></h2>
                <p class="post-date">\(extractDateFromFilename(filename))</p>
            </div>
            """
        }.joined(separator: "\n")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Blog - NightGard</title>
            <link rel="stylesheet" href="../styles.css">
            <style>
                .blog-index {
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 40px 20px;
                }
                
                .blog-header {
                    text-align: center;
                    margin-bottom: 60px;
                }
                
                .blog-header h1 {
                    font-size: 48px;
                    margin-bottom: 16px;
                }
                
                .post-preview {
                    margin-bottom: 40px;
                    padding-bottom: 40px;
                    border-bottom: 1px solid #eee;
                }
                
                .post-preview:last-child {
                    border-bottom: none;
                }
                
                .post-preview h2 {
                    font-size: 32px;
                    margin-bottom: 12px;
                }
                
                .post-preview h2 a {
                    color: #333;
                    text-decoration: none;
                }
                
                .post-preview h2 a:hover {
                    color: #007AFF;
                }
                
                .post-date {
                    color: #999;
                    font-size: 14px;
                }
                
                .no-posts {
                    text-align: center;
                    padding: 60px 20px;
                    color: #999;
                }
                
                .back-home {
                    display: inline-block;
                    margin-top: 40px;
                    padding: 10px 20px;
                    background: #007AFF;
                    color: white;
                    text-decoration: none;
                    border-radius: 6px;
                }
                
                .back-home:hover {
                    background: #0051D5;
                }
            </style>
        </head>
        <body>
            <div class="blog-index">
                <div class="blog-header">
                    <h1>Blog</h1>
                    <p>Thoughts, stories, and ideas</p>
                </div>
                
                \(postListHTML)
                
                <a href="../index.html" class="back-home">← Back to Home</a>
            </div>
        </body>
        </html>
        """
    }
    
    // MARK: - Helper Methods
    
    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
    
    private func formatContent(_ content: String) -> String {
        // Split content into paragraphs and wrap each in <p> tags
        let paragraphs = content.components(separatedBy: "\n\n")
        return paragraphs
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { "<p>\(escapeHTML($0))</p>" }
            .joined(separator: "\n")
    }
    
    private func extractDateFromFilename(_ filename: String) -> String {
        // Extract date from format: 2025-10-11-title.html
        let components = filename.components(separatedBy: "-")
        guard components.count >= 3 else {
            return ""
        }
        
        let dateString = "\(components[0])-\(components[1])-\(components[2])"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .long
            return formatter.string(from: date)
        }
        
        return dateString
    }
}
