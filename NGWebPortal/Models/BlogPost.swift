//
//  BlogPost.swift
//  NGWebPortal
//
//  SwiftData model for blog posts
//

import Foundation
import SwiftData
import AppKit

@Model
class BlogPost {
    var id: UUID
    var title: String
    var subtitle: String
    var content: String
    var featuredImageData: Data?
    var publishedDate: Date
    var author: String
    var isDraft: Bool
    
    init(
        id: UUID = UUID(),
        title: String = "",
        subtitle: String = "",
        content: String = "",
        featuredImageData: Data? = nil,
        publishedDate: Date = Date(),
        author: String = "Michael Fluharty",
        isDraft: Bool = true
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.featuredImageData = featuredImageData
        self.publishedDate = publishedDate
        self.author = author
        self.isDraft = isDraft
    }
    
    // Helper computed property for featured image
    var featuredImage: NSImage? {
        guard let data = featuredImageData else { return nil }
        return NSImage(data: data)
    }
    
    // Generate filename for this post
    var filename: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: publishedDate)
        
        // Create URL-safe title
        let safeTitle = title
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        
        return "\(dateString)-\(safeTitle).html"
    }
}
