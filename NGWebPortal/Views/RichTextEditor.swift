//
//  RichTextEditor.swift
//  NGWebPortal
//
//  WYSIWYG rich text editor component with HTML conversion
//

import SwiftUI
import AppKit

struct RichTextEditor: NSViewRepresentable {
    @Binding var html: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.delegate = context.coordinator
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        
        // Load initial HTML content
        if !html.isEmpty {
            if let attributedString = Self.htmlToAttributedString(html) {
                textView.textStorage?.setAttributedString(attributedString)
            }
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Only update if coordinator indicates external change
        if context.coordinator.needsUpdate {
            if let textView = nsView.documentView as? NSTextView {
                if let attributedString = Self.htmlToAttributedString(html) {
                    textView.textStorage?.setAttributedString(attributedString)
                }
            }
            context.coordinator.needsUpdate = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        var needsUpdate = false
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Convert attributed string to HTML
            if let storage = textView.textStorage {
                parent.html = RichTextEditor.attributedStringToHTML(storage)
            }
        }
    }
    
    // Convert HTML string to NSAttributedString
    private static func htmlToAttributedString(_ html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
    }
    
    // Convert NSAttributedString to HTML string
    private static func attributedStringToHTML(_ attributedString: NSAttributedString) -> String {
        let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let htmlData = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: documentAttributes
        ) else {
            return ""
        }
        
        return String(data: htmlData, encoding: .utf8) ?? ""
    }
}

// Formatting toolbar for rich text editor
struct RichTextToolbar: View {
    let textView: NSTextView?
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: { toggleBold() }) {
                Image(systemName: "bold")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .help("Bold")
            
            Button(action: { toggleItalic() }) {
                Image(systemName: "italic")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .help("Italic")
            
            Button(action: { toggleUnderline() }) {
                Image(systemName: "underline")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .help("Underline")
            
            Divider()
                .frame(height: 20)
            
            Button(action: { insertLink() }) {
                Image(systemName: "link")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .help("Insert Link")
            
            Spacer()
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
    }
    
    private func toggleBold() {
        guard let textView = textView else { return }
        textView.font = NSFontManager.shared.convert(
            textView.font ?? NSFont.systemFont(ofSize: 14),
            toHaveTrait: .boldFontMask
        )
    }
    
    private func toggleItalic() {
        guard let textView = textView else { return }
        textView.font = NSFontManager.shared.convert(
            textView.font ?? NSFont.systemFont(ofSize: 14),
            toHaveTrait: .italicFontMask
        )
    }
    
    private func toggleUnderline() {
        guard let textView = textView,
              let range = textView.selectedRanges.first?.rangeValue,
              let storage = textView.textStorage else { return }
        
        storage.addAttribute(
            .underlineStyle,
            value: NSUnderlineStyle.single.rawValue,
            range: range
        )
    }
    
    private func insertLink() {
        // Simple link insertion - could be enhanced with dialog
        guard let textView = textView,
              let storage = textView.textStorage else { return }
        
        let linkText = "Link"
        let url = "https://example.com"
        
        let attributedString = NSMutableAttributedString(string: linkText)
        attributedString.addAttribute(.link, value: url, range: NSRange(location: 0, length: linkText.count))
        
        storage.insert(attributedString, at: textView.selectedRange().location)
    }
}

#Preview {
    VStack {
        RichTextEditor(html: .constant("<p>Hello <strong>World</strong>!</p>"))
    }
    .frame(height: 300)
    .padding()
}
