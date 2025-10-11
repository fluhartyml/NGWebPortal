//
//  WebServer.swift
//  NGWebPortal
//
//  Hummingbird web server serving site files
//

import Foundation
import Hummingbird
import Observation

@Observable
class WebServer {
    private var serverTask: Task<Void, Never>?
    var isRunning = false
    var serverURL = "http://127.0.0.1:8080"
    var errorMessage = ""
    
    init() {
        // Initialize site folder structure and capture errors
        do {
            try SiteManager.shared.initializeSiteFolder()
            print("✅ Site folder initialized successfully")
        } catch {
            errorMessage = "Failed to initialize site folder: \(error.localizedDescription)"
            print("❌ Site folder initialization error: \(error)")
        }
    }
    
    // Serve static files from site folder
    @Sendable func serveStaticFile(request: Request, context: some RequestContext) async throws -> Response {
        let path = request.uri.path
        let siteFolder = SiteManager.shared.siteFolder
        
        print("📥 Request for: \(path)")
        
        // Determine file path
        let filePath: URL
        if path == "/" || path == "" {
            filePath = siteFolder.appendingPathComponent("index.html")
        } else if path.hasSuffix("/") {
            // Directory request - look for index.html
            let cleanPath = String(path.dropLast())
            filePath = siteFolder.appendingPathComponent(cleanPath).appendingPathComponent("index.html")
        } else {
            // Remove leading slash
            let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
            filePath = siteFolder.appendingPathComponent(cleanPath)
        }
        
        print("📂 Looking for file at: \(filePath.path)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            print("❌ File not found: \(filePath.path)")
            let notFoundHTML = """
                <!DOCTYPE html>
                <html>
                <head><title>404 Not Found</title></head>
                <body>
                    <h1>404 - Page Not Found</h1>
                    <p>The requested file was not found: \(path)</p>
                    <p>Looking for: \(filePath.path)</p>
                    <p><a href="/">Return to home</a></p>
                </body>
                </html>
                """
            return Response(
                status: .notFound,
                headers: [.contentType: "text/html"],
                body: .init(byteBuffer: ByteBuffer(string: notFoundHTML))
            )
        }
        
        print("✅ File found, reading contents...")
        
        // Read file contents
        guard let fileContents = try? String(contentsOf: filePath, encoding: .utf8) else {
            print("❌ Error reading file")
            return Response(
                status: .internalServerError,
                headers: [.contentType: "text/html"],
                body: .init(byteBuffer: ByteBuffer(string: "Error reading file"))
            )
        }
        
        // Determine content type
        let contentType = getContentType(for: filePath.pathExtension)
        
        print("✅ Serving file with content-type: \(contentType)")
        
        return Response(
            status: .ok,
            headers: [.contentType: contentType],
            body: .init(byteBuffer: ByteBuffer(string: fileContents))
        )
    }
    
    // Get MIME type for file extension
    private func getContentType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm":
            return "text/html"
        case "css":
            return "text/css"
        case "js":
            return "application/javascript"
        case "json":
            return "application/json"
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "gif":
            return "image/gif"
        case "svg":
            return "image/svg+xml"
        case "ico":
            return "image/x-icon"
        case "txt":
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }
    
    func start() async throws {
        guard !isRunning else { return }
        
        errorMessage = ""
        
        let router = Router()
        
        // Add explicit routes
        router.get("/", use: serveStaticFile)
        router.get("/about.html", use: serveStaticFile)
        router.get("/blog/", use: serveStaticFile)
        router.get("/portfolio/", use: serveStaticFile)
        router.get("/css/style.css", use: serveStaticFile)
        
        // Catch-all for other files
        router.get("**", use: serveStaticFile)
        
        let app = Application(
            router: router,
            configuration: .init(
                address: .hostname("127.0.0.1", port: 8080)
            )
        )
        
        isRunning = true
        
        print("🚀 NG Web Portal starting on http://127.0.0.1:8080")
        print("📁 Serving files from: \(SiteManager.shared.siteFolder.path)")
        
        serverTask = Task {
            do {
                try await app.run()
            } catch {
                print("❌ Server error: \(error)")
                await MainActor.run {
                    self.errorMessage = "Server error: \(error.localizedDescription)"
                    self.isRunning = false
                }
            }
        }
    }
    
    func stop() async {
        isRunning = false
        errorMessage = ""
        serverTask?.cancel()
        serverTask = nil
        print("🛑 Server stopped")
    }
}
