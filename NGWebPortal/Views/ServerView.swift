//
//  ServerView.swift
//  NGWebPortal
//
//  Server control interface with start/stop and status display
//

import SwiftUI

struct ServerView: View {
    @Bindable var server: WebServer
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Status indicator
            HStack(spacing: 15) {
                Circle()
                    .fill(server.isRunning ? Color.green : Color.red)
                    .frame(width: 20, height: 20)
                
                Text(server.isRunning ? "Server Running" : "Server Stopped")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(server.isRunning ? .primary : .blue)
            }
            
            // Server URL (when running)
            if server.isRunning {
                VStack(spacing: 10) {
                    Text("Server URL:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(server.serverURL)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            // Control buttons
            VStack(spacing: 15) {
                if server.isRunning {
                    HStack(spacing: 20) {
                        Button("Stop Server") {
                            Task {
                                await server.stop()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        
                        Button("View My Site") {
                            if let url = URL(string: server.serverURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Open Site Folder") {
                        SiteManager.shared.openSiteFolder()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Start Server") {
                        Task {
                            try? await server.start()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Open Site Folder") {
                        SiteManager.shared.openSiteFolder()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Error message (if any)
            if !server.errorMessage.isEmpty {
                Text(server.errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Visitor stats (placeholder for v1.0)
            if server.isRunning {
                VStack(spacing: 8) {
                    Text("Visitors Today: 0")
                        .font(.headline)
                    Text("Total Visitors: 0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ServerView(server: WebServer())
}
