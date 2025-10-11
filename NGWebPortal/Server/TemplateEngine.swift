//
//  TemplateEngine.swift
//  NGWebPortal
//
//  Generates HTML pages from data and themes
//

import Foundation

class TemplateEngine {
    
    // Generate home page HTML
    static func generateHomePage(settings: SiteSettings) -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(settings.siteName)</title>
            <style>
                \(generateCSS(settings: settings))
            </style>
        </head>
        <body>
            <header>
                <h1>\(settings.siteName)</h1>
                <p class="tagline">\(settings.tagline)</p>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about">About</a>
                    <a href="/blog">Blog</a>
                    <a href="/portfolio">Portfolio</a>
                </nav>
            </header>
            <main>
                <section class="hero">
                    <h2>Welcome</h2>
                    <p>This is the home page. More content coming soon!</p>
                </section>
            </main>
            <footer>
                <p>&copy; 2025 \(settings.siteName). Powered by NG Web Portal.</p>
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
            <style>
                \(generateCSS(settings: settings))
            </style>
        </head>
        <body>
            <header>
                <h1>\(settings.siteName)</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about">About</a>
                    <a href="/blog">Blog</a>
                    <a href="/portfolio">Portfolio</a>
                </nav>
            </header>
            <main>
                <article class="about">
                    <h2>About</h2>
                    <div class="content">
                        \(settings.aboutText)
                    </div>
                </article>
            </main>
            <footer>
                <p>&copy; 2025 \(settings.siteName). Powered by NG Web Portal.</p>
            </footer>
        </body>
        </html>
        """
    }
    
    // Generate blog list page HTML
    static func generateBlogPage(settings: SiteSettings, posts: [BlogPost]) -> String {
        let publishedPosts = posts.filter { $0.isPublished }.sorted { $0.publishedDate > $1.publishedDate }
        
        let postsHTML = publishedPosts.map { post in
            """
            <article class="blog-post-preview">
                <h3><a href="/blog/\(post.slug)">\(post.title)</a></h3>
                <p class="meta">By \(post.author) on \(post.formattedDate)</p>
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
            <style>
                \(generateCSS(settings: settings))
            </style>
        </head>
        <body>
            <header>
                <h1>\(settings.siteName)</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about">About</a>
                    <a href="/blog">Blog</a>
                    <a href="/portfolio">Portfolio</a>
                </nav>
            </header>
            <main>
                <h2>Blog</h2>
                <div class="blog-posts">
                    \(postsHTML.isEmpty ? "<p>No posts yet.</p>" : postsHTML)
                </div>
            </main>
            <footer>
                <p>&copy; 2025 \(settings.siteName). Powered by NG Web Portal.</p>
            </footer>
        </body>
        </html>
        """
    }
    
    // Generate portfolio page HTML
    static func generatePortfolioPage(settings: SiteSettings, projects: [PortfolioProject]) -> String {
        let publishedProjects = projects.filter { $0.isPublished }.sorted { $0.displayOrder < $1.displayOrder }
        
        let projectsHTML = publishedProjects.map { project in
            """
            <article class="portfolio-project">
                <h3>\(project.title)</h3>
                <div class="project-description">
                    \(project.descriptionHTML)
                </div>
                \(project.projectURL.isEmpty ? "" : "<p><a href=\"\(project.projectURL)\" target=\"_blank\">View Project</a></p>")
            </article>
            """
        }.joined(separator: "\n")
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Portfolio - \(settings.siteName)</title>
            <style>
                \(generateCSS(settings: settings))
            </style>
        </head>
        <body>
            <header>
                <h1>\(settings.siteName)</h1>
                <nav>
                    <a href="/">Home</a>
                    <a href="/about">About</a>
                    <a href="/blog">Blog</a>
                    <a href="/portfolio">Portfolio</a>
                </nav>
            </header>
            <main>
                <h2>Portfolio</h2>
                <div class="portfolio-projects">
                    \(projectsHTML.isEmpty ? "<p>No projects yet.</p>" : projectsHTML)
                </div>
            </main>
            <footer>
                <p>&copy; 2025 \(settings.siteName). Powered by NG Web Portal.</p>
            </footer>
        </body>
        </html>
        """
    }
    
    // Generate CSS based on theme
    private static func generateCSS(settings: SiteSettings) -> String {
        let theme = settings.selectedTheme
        
        return """
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: \(theme.fontFamily);
            font-weight: \(theme.fontWeight);
            background-color: \(theme.backgroundColor);
            color: \(theme.textColor);
            line-height: 1.6;
            padding: 20px;
        }
        
        header {
            max-width: \(theme.maxWidth);
            margin: 0 auto 40px;
            padding-bottom: 20px;
            border-bottom: 2px solid \(settings.accentColor);
        }
        
        header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        
        .tagline {
            font-size: 1.2rem;
            opacity: 0.8;
            margin-bottom: 20px;
        }
        
        nav {
            display: flex;
            gap: 20px;
        }
        
        nav a {
            color: \(settings.accentColor);
            text-decoration: none;
            font-weight: 500;
        }
        
        nav a:hover {
            text-decoration: underline;
        }
        
        main {
            max-width: \(theme.maxWidth);
            margin: 0 auto;
        }
        
        h2 {
            font-size: 2rem;
            margin-bottom: 20px;
            color: \(settings.accentColor);
        }
        
        h3 {
            font-size: 1.5rem;
            margin-bottom: 10px;
        }
        
        article {
            margin-bottom: 40px;
            padding: 20px;
            background-color: \(theme.isLight ? "#F9F9F9" : "#252525");
            border-radius: 8px;
        }
        
        .meta {
            opacity: 0.7;
            font-size: 0.9rem;
            margin-bottom: 10px;
        }
        
        footer {
            max-width: \(theme.maxWidth);
            margin: 60px auto 0;
            padding-top: 20px;
            border-top: 1px solid \(settings.accentColor);
            text-align: center;
            opacity: 0.7;
            font-size: 0.9rem;
        }
        """
    }
}
