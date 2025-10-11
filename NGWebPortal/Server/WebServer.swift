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
        // Initialize site folder structure
        try? SiteManager.shared.initializeSiteFolder()
    }
    
    // Serve static files from site folder
    func serveStaticFile(request: Request, context: some RequestContext) async throws -> Response {
        let path = request.uri.path
        let siteFolder = SiteManager.shared.siteFolder
        
        // Determine file path
        let filePath: URL
        if path == "/" {
            filePath = siteFolder.appendingPathComponent("index.html")
        } else if path.hasSuffix("/") {
            // Directory request - look for index.html
            filePath = siteFolder.appendingPathComponent(path).appendingPathComponent("index.html")
        } else {
            filePath = siteFolder.appendingPathComponent(path)
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            let notFoundHTML = """
                <!DOCTYPE html>
                <html>
                <head><title>404 Not Found</title></head>
                <body>
                    <h1>404 - Page Not Found</h1>
                    <p>The requested file was not found: \(path)</p>
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
        
        // Read file contents
        guard let fileContents = try? String(contentsOf: filePath, encoding: .utf8) else {
            return Response(
                status: .internalServerError,
                headers: [.contentType: "text/html"],
                body: .init(byteBuffer: ByteBuffer(string: "Error reading file"))
            )
        }
        
        // Determine content type
        let contentType = getContentType(for: filePath.pathExtension)
        
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
        router.get("*", use: serveStaticFile)
        
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
