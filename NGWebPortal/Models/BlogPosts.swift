//
//  BlogPost.swift
//  NGWebPortal
//
//  SwiftData model for blog posts
//

import SwiftUI
import SwiftData

@Model
class BlogPost {
    var title: String
    var contentHTML: String  // Rich text stored as HTML
    var author: String
    var publishedDate: Date
    var isPublished: Bool
    
    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    
    init(
        title: String = "Untitled Post",
        contentHTML: String = "",
        author: String = "Author",
        publishedDate: Date = Date(),
        isPublished: Bool = false
    ) {
        self.title = title
        self.contentHTML = contentHTML
        self.author = author
        self.publishedDate = publishedDate
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
    
    // Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: publishedDate)
    }
}
