//
//  Theme.swift
//  NGWebPortal
//
//  Defines visual themes for generated websites
//

import SwiftUI

enum Theme: String, CaseIterable, Codable {
    case lightMinimal = "Light Minimal"
    case lightBold = "Light Bold"
    case darkMinimal = "Dark Minimal"
    case darkBold = "Dark Bold"
    
    var displayName: String {
        return self.rawValue
    }
    
    var isLight: Bool {
        switch self {
        case .lightMinimal, .lightBold:
            return true
        case .darkMinimal, .darkBold:
            return false
        }
    }
    
    // Background colors for generated HTML
    var backgroundColor: String {
        switch self {
        case .lightMinimal:
            return "#FFFFFF"
        case .lightBold:
            return "#F5F5F5"
        case .darkMinimal:
            return "#1A1A1A"
        case .darkBold:
            return "#0D0D0D"
        }
    }
    
    // Text colors for generated HTML
    var textColor: String {
        switch self {
        case .lightMinimal, .lightBold:
            return "#1A1A1A"
        case .darkMinimal, .darkBold:
            return "#F5F5F5"
        }
    }
    
    // Accent color (user customizable, this is default)
    var defaultAccentColor: String {
        switch self {
        case .lightMinimal:
            return "#007AFF"
        case .lightBold:
            return "#FF3B30"
        case .darkMinimal:
            return "#0A84FF"
        case .darkBold:
            return "#FF453A"
        }
    }
    
    // Font family for generated HTML
    var fontFamily: String {
        switch self {
        case .lightMinimal, .darkMinimal:
            return "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
        case .lightBold, .darkBold:
            return "'Helvetica Neue', Helvetica, Arial, sans-serif"
        }
    }
    
    // Font weight
    var fontWeight: String {
        switch self {
        case .lightMinimal, .darkMinimal:
            return "400"
        case .lightBold, .darkBold:
            return "600"
        }
    }
    
    // Max content width
    var maxWidth: String {
        switch self {
        case .lightMinimal, .darkMinimal:
            return "800px"
        case .lightBold, .darkBold:
            return "1200px"
        }
    }
}
