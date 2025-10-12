//
//  AppSettings.swift
//  NGWebPortal
//
//  Application settings and user preferences
//

import SwiftUI
import SwiftData

@Model
final class AppSettings {
    // Site-Wide Settings
    var siteName: String
    var siteTagline: String
    var authorName: String
    var accentColor: String
    
    var accentColorRed: Double {
        get {
            Double(Color(hex: accentColor).cgColor?.components?[0] ?? 0.0)
        }
        set {
            let g = accentColorGreen
            let b = accentColorBlue
            self.accentColor = Color(red: newValue, green: g, blue: b).toHexString()
        }
    }
    var accentColorGreen: Double {
        get {
            Double(Color(hex: accentColor).cgColor?.components?[1] ?? 0.0)
        }
        set {
            let r = accentColorRed
            let b = accentColorBlue
            self.accentColor = Color(red: r, green: newValue, blue: b).toHexString()
        }
    }
    var accentColorBlue: Double {
        get {
            Double(Color(hex: accentColor).cgColor?.components?[2] ?? 0.0)
        }
        set {
            let r = accentColorRed
            let g = accentColorGreen
            self.accentColor = Color(red: r, green: g, blue: newValue).toHexString()
        }
    }
    
    // Blog Settings
    var blogTitle: String
    var blogTagline: String
    
    // Home Settings
    var homeHeroTitle: String
    var homeHeroSubtitle: String
    var homeCtaText: String
    
    // About Settings
    var aboutTitle: String
    var aboutContent: String
    
    // Portfolio Settings
    var portfolioTitle: String
    var portfolioTagline: String
    
    // Server Settings
    var outputDirectory: String
    var serverPort: Int
    
    var createdAt: Date
    
    init(
        siteName: String = "NG Web Portal",
        siteTagline: String = "Welcome to my website",
        authorName: String = "John Q Public",
        accentColor: String = "#007AFF",
        blogTitle: String = "blog",
        blogTagline: String = "thoughts, stories, and ideas",
        homeHeroTitle: String = "Your Site, Your Way",
        homeHeroSubtitle: String = "Share your thoughts, stories, and ideas with the world.",
        homeCtaText: String = "Read the Blog",
        aboutTitle: String = "About Me",
        aboutContent: String = "This is your about page. Edit it to tell your story!",
        portfolioTitle: String = "Portfolio",
        portfolioTagline: String = "My work and projects",
        outputDirectory: String = "",
        serverPort: Int = 8080
    ) {
        self.siteName = siteName
        self.siteTagline = siteTagline
        self.authorName = authorName
        self.accentColor = accentColor
        self.blogTitle = blogTitle
        self.blogTagline = blogTagline
        self.homeHeroTitle = homeHeroTitle
        self.homeHeroSubtitle = homeHeroSubtitle
        self.homeCtaText = homeCtaText
        self.aboutTitle = aboutTitle
        self.aboutContent = aboutContent
        self.portfolioTitle = portfolioTitle
        self.portfolioTagline = portfolioTagline
        self.outputDirectory = outputDirectory
        self.serverPort = serverPort
        self.createdAt = Date()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 122, 255) // fallback blue
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1.0
        )
    }
    func toHexString() -> String {
        let components = self.cgColor?.components ?? [0, 0, 0, 1]
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
