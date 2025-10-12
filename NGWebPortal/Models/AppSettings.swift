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
    var siteName: String
    var siteTagline: String
    var blogTitle: String
    var blogTagline: String
    var outputDirectory: String
    var serverPort: Int
    var createdAt: Date
    
    init(
        siteName: String = "My Site",
        siteTagline: String = "Welcome to my website",
        blogTitle: String = "blog",
        blogTagline: String = "thoughts, stories, and ideas",
        outputDirectory: String = "",
        serverPort: Int = 8080
    ) {
        self.siteName = siteName
        self.siteTagline = siteTagline
        self.blogTitle = blogTitle
        self.blogTagline = blogTagline
        self.outputDirectory = outputDirectory
        self.serverPort = serverPort
        self.createdAt = Date()
    }
}
