//
//  WebServer.swift
//  NGWebPortal
//
//  Hummingbird web server wrapper and HTTP routing
//

import Foundation
import Hummingbird

@Observable
class WebServer {
    var isRunning: Bool = false
    var port: Int = 8080
    var errorMessage: String = ""
    
    private var serverTask: Task<Void, Error>?
    
    init() {}
    
    // Start the web server
    func start() async throws {
        guard !isRunning else { return }
        
        do {
            // Create router
            let router = Router()
            
            // Define routes
            router.get("/") { _, _ in
                return Response(
                    status: .ok,
                    headers: [:],
                    body: .init(byteBuffer: ByteBuffer(string: "<h1>NG Web Portal</h1><p>Server is running!</p>"))
                )
            }
            
            router.get("/about") { _, _ in
                return Response(
                    status: .ok,
                    headers: [:],
                    body: .init(byteBuffer: ByteBuffer(string: "<h1>About</h1><p>About page coming soon</p>"))
                )
            }
            
            router.get("/blog") { _, _ in
                return Response(
                    status: .ok,
                    headers: [:],
                    body: .init(byteBuffer: ByteBuffer(string: "<h1>Blog</h1><p>Blog posts coming soon</p>"))
                )
            }
            
            router.get("/portfolio") { _, _ in
                return Response(
                    status: .ok,
                    headers: [:],
                    body: .init(byteBuffer: ByteBuffer(string: "<h1>Portfolio</h1><p>Portfolio projects coming soon</p>"))
                )
            }
            
            // Create application
            let app = Application(
                router: router,
                configuration: .init(
                    address: .hostname("127.0.0.1", port: port),
                    serverName: "NG Web Portal"
                )
            )
            
            // Start server in background task
            serverTask = Task {
                try await app.run()
            }
            
            // Give server a moment to start
            try await Task.sleep(for: .milliseconds(500))
            
            await MainActor.run {
                self.isRunning = true
                self.errorMessage = ""
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to start server: \(error.localizedDescription)"
                self.isRunning = false
            }
            throw error
        }
    }
    
    // Stop the web server
    func stop() async {
        guard isRunning else { return }
        
        serverTask?.cancel()
        serverTask = nil
        
        await MainActor.run {
            self.isRunning = false
        }
    }
    
    // Get server URL
    var serverURL: String {
        return "http://localhost:\(port)"
    }
}
