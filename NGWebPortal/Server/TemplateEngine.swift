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
        
        // Get all posts for prev/next navigation
        let allPosts = try getAllPostsSorted(in: blogFolder)
        let (prevPost, nextPost) = getAdjacentPosts(for: post.filename, in: allPosts)
        
        // Generate HTML content
        let html = generatePostHTML(post: post, imagePath: imagePath, prevPost: prevPost, nextPost: nextPost)
        
        // Write to file
        let postURL = blogFolder.appendingPathComponent(post.filename)
        try html.write(to: postURL, atomically: true, encoding: .utf8)
        
        // Update blog index
        try updateBlogIndex(siteFolder: siteFolder)
        
        return postURL
    }
    
    private func generatePostHTML(post: BlogPost, imagePath: String, prevPost: String?, nextPost: String?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: post.publishedDate)
        
        let featuredImageHTML = imagePath.isEmpty ? "" : """
        <div class="featured-image">
            <img src="\(imagePath)" alt="\(escapeHTML(post.title))">
        </div>
        """
        
        let prevArrowHTML = prevPost != nil ? """
        <a href="\(prevPost!)" class="nav-arrow prev-arrow" title="Previous Post">
            <span>←</span>
        </a>
        """ : ""
        
        let nextArrowHTML = nextPost != nil ? """
        <a href="\(nextPost!)" class="nav-arrow next-arrow" title="Next Post">
            <span>→</span>
        </a>
        """ : ""
        
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
                    margin-bottom: 12px;
                    line-height: 1.2;
                }
                
                .post-date {
                    color: #999;
                    font-size: 14px;
                    margin-bottom: 20px;
                }
                
                .post-subtitle {
                    font-size: 24px;
                    color: #666;
                    margin-bottom: 24px;
                    line-height: 1.4;
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
                    display: inline-flex;
                    align-items: center;
                    gap: 10px;
                    margin-top: 40px;
                    padding: 12px 24px;
                    background: #007AFF;
                    color: white;
                    text-decoration: none;
                    border-radius: 6px;
                    font-weight: 600;
                }
                
                .back-link:hover {
                    background: #0051D5;
                }
                
                .back-link::before {
                    content: '‹';
                    font-size: 24px;
                    font-weight: bold;
                }
                
                .back-icon {
                    display: inline-flex;
                    align-items: center;
                    gap: 2px;
                }
                
                .back-icon-thumb {
                    width: 10px;
                    height: 14px;
                    border: 1.5px solid white;
                    border-radius: 1px;
                }
                
                .back-icon-lines {
                    display: flex;
                    flex-direction: column;
                    gap: 2px;
                }
                
                .back-icon-line {
                    width: 20px;
                    height: 2px;
                    background: white;
                    border-radius: 1px;
                }
                
                .nav-arrow {
                    position: fixed;
                    top: 50%;
                    transform: translateY(-50%);
                    width: 60px;
                    height: 60px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    background: rgba(0, 122, 255, 0.9);
                    color: white;
                    text-decoration: none;
                    border-radius: 50%;
                    font-size: 32px;
                    transition: all 0.3s ease;
                    z-index: 100;
                }
                
                .nav-arrow:hover {
                    background: rgba(0, 122, 255, 1);
                    transform: translateY(-50%) scale(1.1);
                }
                
                .prev-arrow {
                    left: 40px;
                }
                
                .next-arrow {
                    right: 40px;
                }
                
                @media (max-width: 768px) {
                    .nav-arrow {
                        width: 50px;
                        height: 50px;
                        font-size: 24px;
                    }
                    
                    .prev-arrow {
                        left: 20px;
                    }
                    
                    .next-arrow {
                        right: 20px;
                    }
                }
            </style>
        </head>
        <body>
            \(prevArrowHTML)
            \(nextArrowHTML)
            
            <div class="blog-post">
                \(featuredImageHTML)
                
                <div class="post-header">
                    <h1 class="post-title">\(escapeHTML(post.title))</h1>
                    <p class="post-date">\(dateString)</p>
                    <p class="post-subtitle">\(escapeHTML(post.subtitle))</p>
                </div>
                
                <div class="post-content">
                    \(formatContent(post.content))
                </div>
                
                <a href="index.html" class="back-link">
                    <span class="back-icon">
                        <span class="back-icon-thumb"></span>
                        <span class="back-icon-lines">
                            <span class="back-icon-line"></span>
                            <span class="back-icon-line"></span>
                            <span class="back-icon-line"></span>
                        </span>
                    </span>
                    Back to List
                </a>
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
            // Read the post HTML to extract metadata
            guard let html = try? String(contentsOf: url, encoding: .utf8),
                  let title = extractTitle(from: html),
                  let subtitle = extractSubtitle(from: html),
                  let imagePath = extractImagePath(from: html) else {
                return ""
            }
            
            let filename = url.lastPathComponent
            let dateString = extractDateFromFilename(filename)
            
            return """
            <article class="post-preview">
                <div class="post-thumbnail">
                    \(imagePath.isEmpty ? """
                    <div class="no-image">
                        <span>📝</span>
                    </div>
                    """ : """
                    <img src="\(imagePath)" alt="\(escapeHTML(title))">
                    """)
                </div>
                <div class="post-info">
                    <h2 class="post-title">\(escapeHTML(title))</h2>
                    <p class="post-date">\(dateString)</p>
                    <p class="post-subtitle">\(escapeHTML(subtitle))</p>
                    <a href="\(filename)" class="read-more">Read More →</a>
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
            <title>Blog - NightGard</title>
            <link rel="stylesheet" href="../styles.css">
            <style>
                .blog-index {
                    max-width: 900px;
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
                
                .blog-header p {
                    font-size: 18px;
                    color: #666;
                }
                
                .post-preview {
                    display: flex;
                    gap: 20px;
                    margin-bottom: 30px;
                    padding-bottom: 30px;
                    border-bottom: 1px solid #eee;
                }
                
                .post-preview:last-child {
                    border-bottom: none;
                }
                
                .post-thumbnail {
                    flex-shrink: 0;
                    width: 200px;
                    align-self: stretch;
                    border-radius: 8px;
                    overflow: hidden;
                    background: #f5f5f5;
                }
                
                .post-thumbnail img {
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                }
                
                .no-image {
                    width: 100%;
                    height: 100%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 48px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                }
                
                .post-info {
                    flex: 1;
                    min-width: 0;
                }
                
                .post-title {
                    font-size: 28px;
                    margin-bottom: 8px;
                    line-height: 1.3;
                }
                
                .post-date {
                    font-size: 14px;
                    color: #999;
                    margin-bottom: 12px;
                }
                
                .post-subtitle {
                    font-size: 16px;
                    color: #666;
                    line-height: 1.6;
                    margin-bottom: 16px;
                }
                
                .read-more {
                    display: inline-block;
                    color: #007AFF;
                    text-decoration: none;
                    font-weight: 600;
                    font-size: 16px;
                }
                
                .read-more:hover {
                    text-decoration: underline;
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
    
    // MARK: - Metadata Extraction Helpers
    
    private func extractTitle(from html: String) -> String? {
        guard let range = html.range(of: "<h1 class=\"post-title\">(.*?)</h1>", options: .regularExpression) else {
            return nil
        }
        let match = String(html[range])
        return match.replacingOccurrences(of: "<h1 class=\"post-title\">", with: "")
            .replacingOccurrences(of: "</h1>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractSubtitle(from html: String) -> String? {
        guard let range = html.range(of: "<p class=\"post-subtitle\">(.*?)</p>", options: .regularExpression) else {
            return ""
        }
        let match = String(html[range])
        return match.replacingOccurrences(of: "<p class=\"post-subtitle\">", with: "")
            .replacingOccurrences(of: "</p>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractImagePath(from html: String) -> String? {
        guard let range = html.range(of: "<div class=\"featured-image\">\\s*<img src=\"(.*?)\"", options: .regularExpression) else {
            return ""
        }
        let match = String(html[range])
        if let srcRange = match.range(of: "src=\"(.*?)\"", options: .regularExpression) {
            let src = String(match[srcRange])
            return src.replacingOccurrences(of: "src=\"", with: "")
                .replacingOccurrences(of: "\"", with: "")
        }
        return ""
    }
    
    private func getAllPostsSorted(in blogFolder: URL) throws -> [String] {
        let fileManager = FileManager.default
        return try fileManager.contentsOfDirectory(at: blogFolder, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.pathExtension == "html" && $0.lastPathComponent != "index.html" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2 // Newest first
            }
            .map { $0.lastPathComponent }
    }
    
    private func getAdjacentPosts(for currentFilename: String, in allPosts: [String]) -> (prev: String?, next: String?) {
        guard let currentIndex = allPosts.firstIndex(of: currentFilename) else {
            return (nil, nil)
        }
        
        let prevPost = currentIndex > 0 ? allPosts[currentIndex - 1] : nil
        let nextPost = currentIndex < allPosts.count - 1 ? allPosts[currentIndex + 1] : nil
        
        return (prevPost, nextPost)
    }
}
