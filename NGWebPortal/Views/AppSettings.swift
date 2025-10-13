//
//  AppSettings.swift
//  NGWebPortal
//
//  Application-level preferences (JSON-based, transparent)
//

import Foundation

struct AppSettings: Codable {
    // App Preferences (not website content)
    var lastOpenedSiteFolder: String
    var windowWidth: Double
    var windowHeight: Double
    var windowX: Double
    var windowY: Double
    var developerMode: Bool
    
    static var `default`: AppSettings {
        return AppSettings(
            lastOpenedSiteFolder: "~/Library/Application Support/NGWebPortal/Sites/default",
            windowWidth: 1200,
            windowHeight: 800,
            windowX: 100,
            windowY: 100,
            developerMode: false
        )
    }
}

class AppSettingsManager {
    static let shared = AppSettingsManager()
    
    private init() {}
    
    // MARK: - Settings File Path
    
    private func settingsFilePath() -> String {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = supportDir.appendingPathComponent("NGWebPortal")
        return appDir.appendingPathComponent("app-preferences.json").path
    }
    
    // MARK: - Load Settings
    
    func loadSettings() -> AppSettings {
        let path = settingsFilePath()
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: path) else {
            print("⚠️ No app-preferences.json found, using defaults")
            return .default
        }
        
        // Read and decode
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let settings = try JSONDecoder().decode(AppSettings.self, from: data)
            print("✅ App preferences loaded from: \(path)")
            return settings
        } catch {
            print("❌ Failed to load app preferences: \(error)")
            return .default
        }
    }
    
    // MARK: - Save Settings
    
    func saveSettings(_ settings: AppSettings) {
        let path = settingsFilePath()
        
        // Ensure directory exists
        let directory = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true
        )
        
        // Encode and write
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            try data.write(to: URL(fileURLWithPath: path))
            print("✅ App preferences saved to: \(path)")
        } catch {
            print("❌ Failed to save app preferences: \(error)")
        }
    }
}
