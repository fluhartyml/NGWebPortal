//
//  PortfolioProject.swift
//  NGWebPortal
//
//  SwiftData model for portfolio projects
//

import SwiftUI
import SwiftData

@Model
class PortfolioProject {
    var title: String
    var descriptionHTML: String  // Rich text stored as HTML
    var projectURL: String  // External link to project
    var imagePaths: [String]  // Array of image file paths
    var displayOrder: Int  // For sorting projects
    var isPublished: Bool
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    init(
        title: String = "Untitled Project",
        descriptionHTML: String = "",
        projectURL: String = "",
        imagePaths: [String] = [],
        displayOrder: Int = 0,
        isPublished: Bool = false
    ) {
        self.title = title
        self.descriptionHTML = descriptionHTML
        self.projectURL = projectURL
        self.imagePaths = imagePaths
        self.displayOrder = displayOrder
        self.isPublished = isPublished
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Computed property for URL-friendly slug
    var slug: String {
        return title
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
    }
    
    // Update timestamp helper
    func markUpdated() {
        self.updatedAt = Date()
    }
    
    // Check if project has images
    var hasImages: Bool {
        return !imagePaths.isEmpty
    }
    
    // Get first image for thumbnail
    var thumbnailPath: String? {
        return imagePaths.first
    }
}
