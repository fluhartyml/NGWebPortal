//
//  CustomizeView.swift
//  NGWebPortal
//
//  Site customization interface for theme and content settings
//

import SwiftUI
import SwiftData

struct CustomizeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [SiteSettings]
    
    @State private var siteName: String = ""
    @State private var tagline: String = ""
    @State private var aboutText: String = ""
    @State private var selectedTheme: Theme = .lightMinimal
    @State private var accentColor: Color = .blue
    @State private var authorName: String = ""
    @State private var showingSavedAlert = false
    
    var currentSettings: SiteSettings? {
        return settings.first
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                
                Text("Customize Your Site")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 10)
                
                // Site Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Site Name")
                        .font(.headline)
                    TextField("My Awesome Site", text: $siteName)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Tagline
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tagline")
                        .font(.headline)
                    TextField("Welcome to my corner of the web", text: $tagline)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Author Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Author Name")
                        .font(.headline)
                    TextField("Your Name", text: $authorName)
                        .textFieldStyle(.roundedBorder)
                }
                
                Divider()
                
                // Theme Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Theme")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Theme.allCases, id: \.self) { theme in
                            HStack {
                                Image(systemName: selectedTheme == theme ? "circle.fill" : "circle")
                                    .foregroundColor(selectedTheme == theme ? .accentColor : .gray)
                                Text(theme.displayName)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTheme = theme
                            }
                        }
                    }
                }
                
                // Accent Color
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accent Color")
                        .font(.headline)
                    ColorPicker("Choose accent color", selection: $accentColor)
                }
                
                Divider()
                
                // About Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Me")
                        .font(.headline)
                    TextEditor(text: $aboutText)
                        .frame(height: 150)
                        .border(Color.gray.opacity(0.3), width: 1)
                        .cornerRadius(4)
                }
                
                // Save Button
                Button(action: saveSettings) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
            }
            .padding(30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: loadSettings)
        .alert("Settings Saved", isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your site customization has been saved successfully.")
        }
    }
    
    private func loadSettings() {
        if let existing = currentSettings {
            siteName = existing.siteName
            tagline = existing.tagline
            aboutText = existing.aboutText
            selectedTheme = existing.selectedTheme
            authorName = existing.authorName
            accentColor = Color(hex: existing.accentColor) ?? .blue
        } else {
            // Create default settings if none exist
            let newSettings = SiteSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
        }
    }
    
    private func saveSettings() {
        if let existing = currentSettings {
            existing.siteName = siteName
            existing.tagline = tagline
            existing.aboutText = aboutText
            existing.selectedTheme = selectedTheme
            existing.authorName = authorName
            existing.customAccentColor = accentColor.toHex()
            existing.markUpdated()
        } else {
            let newSettings = SiteSettings(
                siteName: siteName,
                tagline: tagline,
                aboutText: aboutText,
                selectedTheme: selectedTheme,
                customAccentColor: accentColor.toHex(),
                authorName: authorName
            )
            modelContext.insert(newSettings)
        }
        
        try? modelContext.save()
        showingSavedAlert = true
    }
}

// Helper extension for Color to Hex conversion
extension Color {
    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    CustomizeView()
        .modelContainer(for: SiteSettings.self, inMemory: true)
}
