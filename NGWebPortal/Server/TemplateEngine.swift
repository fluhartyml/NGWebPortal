//
//  TemplateEngine.swift
//  NGWebPortal
//
//  Generates HTML files from blog posts and portfolio projects
//

import Foundation

class TemplateEngine {
    static let shared = TemplateEngine()
    
    private init() {}
    
    // Generate individual blog post HTML
    static func generateBlogPost(post: BlogPost, settings: SiteSettings) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(post.title) - \(settings.siteName)</title>
            <link rel="stylesheet" href="/css/style.css">
        </head>
        <body>
            <header>
                <h1>\(settings.siteName)</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about.html">About</a>
                    <a href="/blog/">Blog</a>
                    <a href="/portfolio/">Portfolio</a>
                </nav>
            </header>
            <main>
                <article class="blog-post">
                    <h1>\(post.title)</h1>
                    <p class="subtitle">\(post.subtitle)</p>
                    <p class="meta">By \(post.author) on \(post.publishedDate.formatted(date: .long, time: .omitted))</p>
                    <div class="content">
                        \(post.content)
                    </div>
                </article>
            </main>
            <footer>
                <p>&copy; 2025 \(settings.siteName)</p>
            </footer>
        </body>
        </html>
        """
    }
    
    // Generate about page HTML
    static func generateAboutPage(settings: SiteSettings) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>About - \(settings.siteName)</title>
            <link rel="stylesheet" href="/css/style.css">
        </head>
        <body>
            <header>
                <h1>\(settings.siteName)</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about.html">About</a>
                    <a href="/blog/">Blog</a>
                    <a href="/portfolio/">Portfolio</a>
                </nav>
            </header>
            <main>
                <article>
                    <h2>About</h2>
                    <p>\(settings.aboutText)</p>
                </article>
            </main>
            <footer>
                <p>&copy; 2025 \(settings.siteName)</p>
            </footer>
        </body>
        </html>
        """
    }
    
    // Generate blog list page HTML
    static func generateBlogPage(settings: SiteSettings, posts: [BlogPost]) -> String {
        let publishedPosts = posts.filter { !$0.isDraft }.sorted {
            $0.publishedDate > $1.publishedDate }
        
        let postsHTML = publishedPosts.map { post in
            """
            <article class="blog-post-preview">
                <h3><a href="/blog/\(post.filename)">\(post.title)</a></h3>
                <p class="meta">By \(post.author) on \(post.publishedDate.formatted(date: .long, time: .omitted))</p>
                <p>\(post.subtitle)</p>
            </article>
            """
        }.joined(separator: "\n")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Blog - \(settings.siteName)</title>
            <link rel="stylesheet" href="/css/style.css">
        </head>
        <body>
            <header>
                <h1>\(settings.siteName)</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about.html">About</a>
                    <a href="/blog/">Blog</a>
                    <a href="/portfolio/">Portfolio</a>
                </nav>
            </header>
            <main>
                <h2>Blog Posts</h2>
                \(postsHTML.isEmpty ? "<p>No posts yet.</p>" : postsHTML)
            </main>
            <footer>
                <p>&copy; 2025 \(settings.siteName)</p>
            </footer>
        </body>
        </html>
        """
    }
}
