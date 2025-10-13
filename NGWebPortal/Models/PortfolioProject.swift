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
    var subtitle: String
    var projectDescription: String   // Rich text as HTML
    var technologies: String        // e.g., "Swift, SwiftUI"
    var projectURL: String
    var featuredImageData: Data?
    var createdAt: Date
    var isDraft: Bool

    init(
        title: String = "",
        subtitle: String = "",
        projectDescription: String = "",
        technologies: String = "",
        projectURL: String = "",
        featuredImageData: Data? = nil,
        isDraft: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.projectDescription = projectDescription
        self.technologies = technologies
        self.projectURL = projectURL
        self.featuredImageData = featuredImageData
        self.createdAt = Date()
        self.isDraft = isDraft
    }

    var slug: String {
        return title
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
    }
}
