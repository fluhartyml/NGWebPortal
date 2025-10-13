//
//  SettingsManager.swift
//  NGWebPortal
//
//  Manages site settings via JSON file in site folder
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager()
    
    private init() {}
    
    // MARK: - Settings File Path
    
    private func settingsFilePath() -> String {
        let defaultSettings = SiteSettings.default
        let expandedPath = (defaultSettings.outputDirectory as NSString).expandingTildeInPath
        return (expandedPath as NSString).appendingPathComponent("settings.json")
    }
    
    // MARK: - Load Settings
    
    func loadSettings() -> SiteSettings {
        let path = settingsFilePath()
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: path) else {
            print("⚠️ No settings.json found, using defaults")
            return .default
        }
        
        // Read and decode
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let settings = try JSONDecoder().decode(SiteSettings.self, from: data)
            print("✅ Settings loaded from: \(path)")
            return settings
        } catch {
            print("❌ Failed to load settings: \(error)")
            return .default
        }
    }
    
    // MARK: - Save Settings
    
    func saveSettings(_ settings: SiteSettings) {
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
            print("✅ Settings saved to: \(path)")
        } catch {
            print("❌ Failed to save settings: \(error)")
        }
    }
    
    // MARK: - Color Conversion Helpers
    
    func hexFromRGB(red: Double, green: Double, blue: Double) -> String {
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    func rgbFromHex(_ hex: String) -> (red: Double, green: Double, blue: Double) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        return (red, green, blue)
    }
}
