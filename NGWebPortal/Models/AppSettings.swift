//
//  AppSettings.swift
//  NGWebPortal
//
//  Global application settings and site-wide customization
//

import SwiftUI
import SwiftData

@Model
final class AppSettings {
    // Site Identity
    var siteName: String
    var siteTagline: String
    var authorName: String
    
    // Branding
    var logoFileName: String
    var useLogo: Bool
    
    // Colors
    var accentColor: String
    
    // Computed properties for RGB sliders
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
        logoFileName: String = "",
        useLogo: Bool = false,
        accentColor: String = "#007AFF",
        blogTitle: String = "Blog",
        blogTagline: String = "Thoughts, stories, and ideas",
        homeHeroTitle: String = "Your Site, Your Way",
        homeHeroSubtitle: String = "Share your thoughts, stories, and ideas with the world.",
        homeCtaText: String = "Read the Blog",
        aboutTitle: String = "About Me",
        aboutContent: String = "This is your about page. Edit it to tell your story!",
        portfolioTitle: String = "Portfolio",
        portfolioTagline: String = "Selected work and projects",
        outputDirectory: String = "~/Library/Application Support/NGWebPortal/Sites/default",
        serverPort: Int = 8080
    ) {
        self.siteName = siteName
        self.siteTagline = siteTagline
        self.authorName = authorName
        self.logoFileName = logoFileName
        self.useLogo = useLogo
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

// Color extension for hex conversion
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHexString() -> String {
        guard let components = self.cgColor?.components, components.count >= 3 else {
            return "#007AFF"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}
