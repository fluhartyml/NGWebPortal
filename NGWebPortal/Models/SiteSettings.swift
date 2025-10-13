//
//  SiteSettings.swift
//  NGWebPortal
//
//  Site configuration and customization settings (JSON-based)
//

import Foundation
import SwiftUI

struct SiteSettings: Codable {
    var siteName: String
    var siteTagline: String
    var authorName: String
    var logoFileName: String
    var useLogo: Bool
    var accentColor: String
    var blogTitle: String
    var blogTagline: String
    var homeHeroTitle: String
    var homeHeroSubtitle: String
    var homeCtaText: String
    var aboutTitle: String
    var aboutContent: String
    var portfolioTitle: String
    var portfolioTagline: String
    var outputDirectory: String
    var serverPort: Int
    
    static var `default`: SiteSettings {
        return SiteSettings(
            siteName: "NG Web Portal",
            siteTagline: "Welcome to my website",
            authorName: "John Q Public",
            logoFileName: "",
            useLogo: false,
            accentColor: "#007AFF",
            blogTitle: "Blog",
            blogTagline: "Thoughts, stories, and ideas",
            homeHeroTitle: "Your Site, Your Way",
            homeHeroSubtitle: "Share your thoughts, stories, and ideas with the world.",
            homeCtaText: "Read the Blog",
            aboutTitle: "About Me",
            aboutContent: "This is your about page. Edit it to tell your story!",
            portfolioTitle: "Portfolio",
            portfolioTagline: "Selected work and projects",
            outputDirectory: "~/Library/Application Support/NGWebPortal/Sites/default",
            serverPort: 8080
        )
    }
}

// MARK: - Color Extension for Hex Conversion

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
