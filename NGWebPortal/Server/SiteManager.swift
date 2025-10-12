//
//  SiteManager.swift
//  NGWebPortal
//
//  Manages site folder structure and HTML templates
//

import Foundation
import AppKit

class SiteManager {
    static let shared = SiteManager()
    
    private(set) var currentSiteFolder: URL?
    
    private init() {
        initializeSiteFolder()
    }
    
    private func initializeSiteFolder() {
        // Get app support directory
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("❌ Could not find Application Support directory")
            return
        }
        
        // Create NGWebPortal/Sites/default structure
        let sitesFolder = appSupport
            .appendingPathComponent("NGWebPortal")
            .appendingPathComponent("Sites")
            .appendingPathComponent("default")
        
        do {
            try FileManager.default.createDirectory(at: sitesFolder, withIntermediateDirectories: true)
            currentSiteFolder = sitesFolder
            
            // Create initial structure
            try createInitialStructure(at: sitesFolder)
            
            print("✅ Site folder initialized: \(sitesFolder.path)")
        } catch {
            print("❌ Failed to create site folder: \(error)")
        }
    }
    
    private func createInitialStructure(at siteFolder: URL) throws {
        let fileManager = FileManager.default
        
        // Create subdirectories
        let subdirs = ["blog", "images", "css", "js"]
        for dir in subdirs {
            let dirURL = siteFolder.appendingPathComponent(dir)
            if !fileManager.fileExists(atPath: dirURL.path) {
                try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
            }
        }
        
        // Create index.html if it doesn't exist
        let indexURL = siteFolder.appendingPathComponent("index.html")
        if !fileManager.fileExists(atPath: indexURL.path) {
            let indexHTML = generateIndexHTML()
            try indexHTML.write(to: indexURL, atomically: true, encoding: .utf8)
        }
        
        // Create styles.css if it doesn't exist
        let cssURL = siteFolder.appendingPathComponent("styles.css")
        if !fileManager.fileExists(atPath: cssURL.path) {
            let css = generateDefaultCSS()
            try css.write(to: cssURL, atomically: true, encoding: .utf8)
        }
        
        // Create blog index if it doesn't exist
        let blogIndexURL = siteFolder.appendingPathComponent("blog/index.html")
        if !fileManager.fileExists(atPath: blogIndexURL.path) {
            try TemplateEngine.shared.updateBlogIndex(siteFolder: siteFolder)
        }
        
        print("✅ Site folder initialized successfully")
    }
    
    private func generateIndexHTML() -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>NightGard - Home</title>
            <link rel="stylesheet" href="styles.css">
        </head>
        <body>
            <div class="container">
                <header>
                    <h1>Welcome to NightGard</h1>
                    <nav>
                        <a href="index.html">Home</a>
                        <a href="blog/index.html">Blog</a>
                    </nav>
                </header>
                
                <main>
                    <section class="hero">
                        <h2>Your Personal Web Portal</h2>
                        <p>Share your thoughts, stories, and ideas with the world.</p>
                        <a href="blog/index.html" class="cta-button">Read the Blog</a>
                    </section>
                </main>
                
                <footer>
                    <p>&copy; 2025 NightGard. All rights reserved.</p>
                </footer>
            </div>
        </body>
        </html>
        """
    }
    
    private func generateDefaultCSS() -> String {
        return """
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
            padding: 20px;
            background: white;
            min-height: 100vh;
        }
        
        header {
            padding: 40px 0;
            border-bottom: 2px solid #007AFF;
            margin-bottom: 40px;
        }
        
        header h1 {
            font-size: 36px;
            margin-bottom: 20px;
        }
        
        nav {
            display: flex;
            gap: 20px;
        }
        
        nav a {
            color: #007AFF;
            text-decoration: none;
            font-weight: 500;
            padding: 8px 16px;
            border-radius: 6px;
            transition: background 0.2s;
        }
        
        nav a:hover {
            background: #f0f0f0;
        }
        
        main {
            padding: 40px 0;
        }
        
        .hero {
            text-align: center;
            padding: 60px 20px;
        }
        
        .hero h2 {
            font-size: 48px;
            margin-bottom: 20px;
        }
        
        .hero p {
            font-size: 20px;
            color: #666;
            margin-bottom: 30px;
        }
        
        .cta-button {
            display: inline-block;
            padding: 12px 30px;
            background: #007AFF;
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: background 0.2s;
        }
        
        .cta-button:hover {
            background: #0051D5;
        }
        
        footer {
            margin-top: 60px;
            padding: 40px 0;
            border-top: 1px solid #eee;
            text-align: center;
            color: #999;
        }
        """
    }
    
    func revealSiteFolder() {
        guard let folder = currentSiteFolder else { return }
        NSWorkspace.shared.selectFile(nil as String?, inFileViewerRootedAtPath: folder.path)
    }
}
