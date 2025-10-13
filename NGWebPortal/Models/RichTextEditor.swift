//
//  RichTextEditor.swift
//  NGWebPortal
//
//  Native WYSIWYG rich text editor with formatting toolbar
//

import SwiftUI
import AppKit

public struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textStorage?.setAttributedString(attributedText)
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        if textView.attributedString() != attributedText {
            textView.textStorage?.setAttributedString(attributedText)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedText = textView.attributedString()
        }
    }
}

public struct RichTextEditorView: View {
    @Binding var attributedText: NSAttributedString
    @State private var textView: NSTextView?
    
    public var body: some View {
        VStack(spacing: 0) {
            // Formatting Toolbar
            HStack(spacing: 16) {
                // Text Style Buttons
                Group {
                    Button(action: { toggleBold() }) {
                        Image(systemName: "bold")
                            .help("Bold (⌘B)")
                    }
                    
                    Button(action: { toggleItalic() }) {
                        Image(systemName: "italic")
                            .help("Italic (⌘I)")
                    }
                    
                    Button(action: { toggleUnderline() }) {
                        Image(systemName: "underline")
                            .help("Underline (⌘U)")
                    }
                }
                
                Divider()
                    .frame(height: 20)
                
                // Header Buttons
                Group {
                    Button(action: { applyHeading(level: 1) }) {
                        Text("H1")
                            .font(.system(size: 12, weight: .bold))
                            .help("Heading 1")
                    }
                    
                    Button(action: { applyHeading(level: 2) }) {
                        Text("H2")
                            .font(.system(size: 12, weight: .bold))
                            .help("Heading 2")
                    }
                    
                    Button(action: { applyHeading(level: 3) }) {
                        Text("H3")
                            .font(.system(size: 12, weight: .bold))
                            .help("Heading 3")
                    }
                }
                
                Divider()
                    .frame(height: 20)
                
                // List Buttons
                Group {
                    Button(action: { toggleBulletList() }) {
                        Image(systemName: "list.bullet")
                            .help("Bullet List")
                    }
                    
                    Button(action: { toggleNumberedList() }) {
                        Image(systemName: "list.number")
                            .help("Numbered List")
                    }
                }
                
                Divider()
                    .frame(height: 20)
                
                // Link Button
                Button(action: { insertLink() }) {
                    Image(systemName: "link")
                        .help("Insert Link")
                }
                
                Spacer()
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Text Editor
            RichTextEditorWrapper(attributedText: $attributedText, textView: $textView)
                .frame(maxHeight: CGFloat.greatestFiniteMagnitude)
        }
    }
    
    // MARK: - Formatting Actions
    
    private func toggleBold() {
        guard let textView = textView else { return }
        textView.window?.makeFirstResponder(textView)
        
        if let font = textView.font {
            let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
            
            if isBold {
                textView.removeFontTrait(.bold)
            } else {
                textView.addFontTrait(.bold)
            }
        }
    }
    
    private func toggleItalic() {
        guard let textView = textView else { return }
        textView.window?.makeFirstResponder(textView)
        
        if let font = textView.font {
            let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
            
            if isItalic {
                textView.removeFontTrait(.italic)
            } else {
                textView.addFontTrait(.italic)
            }
        }
    }
    
    private func toggleUnderline() {
        guard let textView = textView else { return }
        textView.window?.makeFirstResponder(textView)
        textView.underline(nil)
    }
    
    private func applyHeading(level: Int) {
        guard let textView = textView else { return }
        textView.window?.makeFirstResponder(textView)
        
        let fontSize: CGFloat = {
            switch level {
            case 1: return 28
            case 2: return 24
            case 3: return 20
            default: return 14
            }
        }()
        
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
        
        let range = textView.selectedRange()
        if range.length > 0 {
            textView.textStorage?.addAttribute(.font, value: font, range: range)
        } else {
            textView.typingAttributes[.font] = font
        }
    }
    
    private func toggleBulletList() {
        guard let textView = textView else { return }
        textView.window?.makeFirstResponder(textView)
        
        let range = textView.selectedRange()
        let lineRange = (textView.string as NSString).lineRange(for: range)
        let line = (textView.string as NSString).substring(with: lineRange)
        
        if line.hasPrefix("• ") {
            let newLine = String(line.dropFirst(2))
            textView.replaceCharacters(in: lineRange, with: newLine)
        } else {
            let newLine = "• " + line
            textView.replaceCharacters(in: lineRange, with: newLine)
        }
    }
    
    private func toggleNumberedList() {
        guard let textView = textView else { return }
        textView.window?.makeFirstResponder(textView)
        
        let range = textView.selectedRange()
        let lineRange = (textView.string as NSString).lineRange(for: range)
        let line = (textView.string as NSString).substring(with: lineRange)
        
        if line.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
            let newLine = line.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: .regularExpression)
            textView.replaceCharacters(in: lineRange, with: newLine)
        } else {
            let newLine = "1. " + line
            textView.replaceCharacters(in: lineRange, with: newLine)
        }
    }
    
    private func insertLink() {
        guard let textView = textView else { return }
        textView.window?.makeFirstResponder(textView)
        
        let alert = NSAlert()
        alert.messageText = "Insert Link"
        alert.informativeText = "Enter the URL:"
        alert.addButton(withTitle: "Insert")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        input.placeholderString = "https://example.com"
        alert.accessoryView = input
        
        alert.window.initialFirstResponder = input
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let urlString = input.stringValue
            if !urlString.isEmpty {
                let range = textView.selectedRange()
                let selectedText = (textView.string as NSString).substring(with: range)
                let linkText = selectedText.isEmpty ? urlString : selectedText
                
                if let url = URL(string: urlString) {
                    let attributedString = NSMutableAttributedString(string: linkText)
                    attributedString.addAttribute(.link, value: url, range: NSRange(location: 0, length: linkText.count))
                    attributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: NSRange(location: 0, length: linkText.count))
                    attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: linkText.count))
                    
                    textView.textStorage?.replaceCharacters(in: range, with: attributedString)
                }
            }
        }
    }
}

struct RichTextEditorWrapper: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var textView: NSTextView?
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }
        
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .labelColor
        textView.backgroundColor = .textBackgroundColor
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textStorage?.setAttributedString(attributedText)
        
        DispatchQueue.main.async {
            self.textView = textView
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        if textView.attributedString() != attributedText {
            textView.textStorage?.setAttributedString(attributedText)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorWrapper
        
        init(_ parent: RichTextEditorWrapper) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.attributedText = textView.attributedString()
        }
    }
}

extension NSTextView {
    func addFontTrait(_ trait: NSFontDescriptor.SymbolicTraits) {
        guard let font = self.font else { return }
        
        var traits = font.fontDescriptor.symbolicTraits
        traits.insert(trait)
        
        if let newFont = NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(traits), size: font.pointSize) {
            let range = selectedRange()
            if range.length > 0 {
                textStorage?.addAttribute(.font, value: newFont, range: range)
            } else {
                typingAttributes[.font] = newFont
            }
        }
    }
    
    func removeFontTrait(_ trait: NSFontDescriptor.SymbolicTraits) {
        guard let font = self.font else { return }
        
        var traits = font.fontDescriptor.symbolicTraits
        traits.remove(trait)
        
        if let newFont = NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(traits), size: font.pointSize) {
            let range = selectedRange()
            if range.length > 0 {
                textStorage?.addAttribute(.font, value: newFont, range: range)
            } else {
                typingAttributes[.font] = newFont
            }
        }
    }
}

#Preview {
    RichTextEditorView(attributedText: .constant(NSAttributedString(string: "Start typing...")))
        .frame(height: 400)
}
