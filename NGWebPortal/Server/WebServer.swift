//
//  WebServer.swift
//  NGWebPortal
//
//  Hummingbird web server serving site files
//

import Foundation
import Hummingbird
import Observation
internal import NIOFoundationCompat

@Observable
class WebServer {
    private var serverTask: Task<Void, Never>?
    var isRunning = false
    var serverURL = "http://127.0.0.1:8080"
    var errorMessage = ""
    
    init() {
        // Site folder is automatically initialized by SiteManager singleton
        if let folder = SiteManager.shared.currentSiteFolder {
            print("✅ Site folder ready: \(folder.path)")
        } else {
            errorMessage = "Failed to initialize site folder"
            print("❌ Site folder initialization failed")
        }
    }
    
    // Serve static files from site folder
    @Sendable func serveStaticFile(request: Request, context: some RequestContext) async throws -> Response {
        let path = request.uri.path
        
        guard let siteFolder = SiteManager.shared.currentSiteFolder else {
            print("❌ Site folder not available")
            return Response(
                status: .internalServerError,
                headers: [.contentType: "text/html"],
                body: .init(byteBuffer: ByteBuffer(string: "Site folder not initialized"))
            )
        }
        
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
        
        // Determine content type
        let contentType = getContentType(for: filePath.pathExtension)
        let ext = filePath.pathExtension.lowercased()
        
        // Read binary data for images and other binary files
        if ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "gif" || ext == "ico" {
            guard let fileData = try? Data(contentsOf: filePath) else {
                print("❌ Error reading binary file")
                return Response(
                    status: .internalServerError,
                    headers: [.contentType: "text/html"],
                    body: .init(byteBuffer: ByteBuffer(string: "Error reading file"))
                )
            }
            
            print("✅ Serving binary file (\(fileData.count) bytes) with content-type: \(contentType)")
            
            var buffer = ByteBuffer()
            buffer.writeData(fileData)
            
            return Response(
                status: .ok,
                headers: [.contentType: contentType],
                body: .init(byteBuffer: buffer)
            )
        }
        
        // Read text files as UTF-8 strings
        guard let fileContents = try? String(contentsOf: filePath, encoding: .utf8) else {
            print("❌ Error reading text file")
            return Response(
                status: .internalServerError,
                headers: [.contentType: "text/html"],
                body: .init(byteBuffer: ByteBuffer(string: "Error reading file"))
            )
        }
        
        print("✅ Serving text file with content-type: \(contentType)")
        
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
        
        guard let siteFolder = SiteManager.shared.currentSiteFolder else {
            throw NSError(domain: "WebServer", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Site folder not initialized"
            ])
        }
        
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
        print("📁 Serving files from: \(siteFolder.path)")
        
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
