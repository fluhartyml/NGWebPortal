//
//  SiteManager.swift
//  NGWebPortal
//
//  Manages site folder structure and default template files
//

import Foundation
import AppKit

class SiteManager {
    static let shared = SiteManager()
    
    // Site folder location
    var siteFolder: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("NGWebPortal/Sites/default")
    }
    
    // Initialize site folder structure
    func initializeSiteFolder() throws {
        let fileManager = FileManager.default
        
        // Create folder structure if it doesn't exist
        if !fileManager.fileExists(atPath: siteFolder.path) {
            try fileManager.createDirectory(at: siteFolder, withIntermediateDirectories: true)
            
            // Create subfolders
            try fileManager.createDirectory(at: siteFolder.appendingPathComponent("blog"), withIntermediateDirectories: true)
            try fileManager.createDirectory(at: siteFolder.appendingPathComponent("portfolio"), withIntermediateDirectories: true)
            try fileManager.createDirectory(at: siteFolder.appendingPathComponent("css"), withIntermediateDirectories: true)
            try fileManager.createDirectory(at: siteFolder.appendingPathComponent("js"), withIntermediateDirectories: true)
            try fileManager.createDirectory(at: siteFolder.appendingPathComponent("images"), withIntermediateDirectories: true)
            
            // Create default files
            try createDefaultFiles()
        }
    }
    
    // Create default HTML and CSS files
    private func createDefaultFiles() throws {
        // index.html
        try defaultIndexHTML.write(to: siteFolder.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        
        // about.html
        try defaultAboutHTML.write(to: siteFolder.appendingPathComponent("about.html"), atomically: true, encoding: .utf8)
        
        // blog/index.html
        try defaultBlogHTML.write(to: siteFolder.appendingPathComponent("blog/index.html"), atomically: true, encoding: .utf8)
        
        // portfolio/index.html
        try defaultPortfolioHTML.write(to: siteFolder.appendingPathComponent("portfolio/index.html"), atomically: true, encoding: .utf8)
        
        // css/style.css
        try defaultCSS.write(to: siteFolder.appendingPathComponent("css/style.css"), atomically: true, encoding: .utf8)
    }
    
    // Open site folder in Finder
    func openSiteFolder() {
        NSWorkspace.shared.open(siteFolder)
    }
    
    // Default HTML Templates
    private var defaultIndexHTML: String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>NG Web Portal</title>
            <link rel="stylesheet" href="/css/style.css">
        </head>
        <body>
            <header>
                <h1>Welcome to NG Web Portal</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about.html">About</a>
                    <a href="/blog/">Blog</a>
                    <a href="/portfolio/">Portfolio</a>
                </nav>
            </header>
            <main>
                <section class="hero">
                    <h2>Your Site, Your Way</h2>
                    <p>Edit this file at: <code>~/Library/Application Support/NGWebPortal/Sites/default/index.html</code></p>
                    <p>Click "Open Site Folder" in the app to start customizing!</p>
                </section>
            </main>
            <footer>
                <p>&copy; 2025 Powered by NG Web Portal</p>
            </footer>
        </body>
        </html>
        """
    }
    
    private var defaultAboutHTML: String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>About - NG Web Portal</title>
            <link rel="stylesheet" href="/css/style.css">
        </head>
        <body>
            <header>
                <h1>About</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about.html">About</a>
                    <a href="/blog/">Blog</a>
                    <a href="/portfolio/">Portfolio</a>
                </nav>
            </header>
            <main>
                <article>
                    <h2>About Me</h2>
                    <p>This is your about page. Edit it to tell your story!</p>
                </article>
            </main>
            <footer>
                <p>&copy; 2025 Powered by NG Web Portal</p>
            </footer>
        </body>
        </html>
        """
    }
    
    private var defaultBlogHTML: String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Blog - NG Web Portal</title>
            <link rel="stylesheet" href="/css/style.css">
        </head>
        <body>
            <header>
                <h1>Blog</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about.html">About</a>
                    <a href="/blog/">Blog</a>
                    <a href="/portfolio/">Portfolio</a>
                </nav>
            </header>
            <main>
                <h2>Recent Posts</h2>
                <p>No posts yet. Start writing!</p>
            </main>
            <footer>
                <p>&copy; 2025 Powered by NG Web Portal</p>
            </footer>
        </body>
        </html>
        """
    }
    
    private var defaultPortfolioHTML: String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Portfolio - NG Web Portal</title>
            <link rel="stylesheet" href="/css/style.css">
        </head>
        <body>
            <header>
                <h1>Portfolio</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about.html">About</a>
                    <a href="/blog/">Blog</a>
                    <a href="/portfolio/">Portfolio</a>
                </nav>
            </header>
            <main>
                <h2>My Work</h2>
                <p>Showcase your projects here!</p>
            </main>
            <footer>
                <p>&copy; 2025 Powered by NG Web Portal</p>
            </footer>
        </body>
        </html>
        """
    }
    
    private var defaultCSS: String {
        """
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
            background: #007AFF;
            color: white;
            padding: 2rem;
            text-align: center;
        }
        
        header h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
        }
        
        nav {
            display: flex;
            gap: 2rem;
            justify-content: center;
        }
        
        nav a {
            color: white;
            text-decoration: none;
            font-weight: 500;
        }
        
        nav a:hover {
            text-decoration: underline;
        }
        
        main {
            max-width: 800px;
            margin: 3rem auto;
            padding: 0 2rem;
        }
        
        h2 {
            font-size: 2rem;
            margin-bottom: 1rem;
            color: #007AFF;
        }
        
        p {
            margin-bottom: 1rem;
        }
        
        code {
            background: #f5f5f5;
            padding: 0.2rem 0.5rem;
            border-radius: 4px;
            font-size: 0.9rem;
        }
        
        .hero {
            text-align: center;
            padding: 3rem 0;
        }
        
        footer {
            text-align: center;
            padding: 2rem;
            background: #f5f5f5;
            margin-top: 4rem;
        }
        """
    }
}
