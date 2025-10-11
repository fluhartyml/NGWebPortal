//
//  SiteSettings.swift
//  NGWebPortal
//
//  SwiftData model for site configuration and customization
//

import SwiftUI
import SwiftData

@Model
class SiteSettings {
    var siteName: String
    var tagline: String
    var aboutText: String
    var selectedTheme: Theme
    var customAccentColor: String
    var authorName: String
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    init(
        siteName: String = "My Site",
        tagline: String = "Welcome to my corner of the web",
        aboutText: String = "This is my personal website.",
        selectedTheme: Theme = .lightMinimal,
        customAccentColor: String = "",
        authorName: String = "Site Owner"
    ) {
        self.siteName = siteName
        self.tagline = tagline
        self.aboutText = aboutText
        self.selectedTheme = selectedTheme
        self.customAccentColor = customAccentColor.isEmpty ? selectedTheme.defaultAccentColor : customAccentColor
        self.authorName = authorName
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Computed property for actual accent color to use
    var accentColor: String {
        return customAccentColor.isEmpty ? selectedTheme.defaultAccentColor : customAccentColor
    }
    
    // Update timestamp helper
    func markUpdated() {
        self.updatedAt = Date()
    }
}
