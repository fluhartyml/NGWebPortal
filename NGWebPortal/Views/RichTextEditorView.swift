import SwiftUI
import AppKit

// macOS-only Rich Text Editor using NSTextView wrapped in NSViewRepresentable
public struct RichTextEditorView: NSViewRepresentable {
    @Binding public var attributedText: NSAttributedString

    public init(attributedText: Binding<NSAttributedString>) {
        self._attributedText = attributedText
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isRichText = true
        textView.isEditable = true
        textView.allowsUndo = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.usesFindBar = true
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .textBackgroundColor
        textView.delegate = context.coordinator

        // Set default typing attributes if none are present
        if textView.typingAttributes[.font] == nil {
            textView.typingAttributes[.font] = NSFont.systemFont(ofSize: 14)
        }

        // Apply initial content
        textView.textStorage?.setAttributedString(attributedText)

        let scrollView = NSScrollView()
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor

        context.coordinator.textView = textView
        return scrollView
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        // Avoid feedback loop by only updating when the content actually differs
        if textView.attributedString() != attributedText {
            // Preserve current selection where possible
            let selectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedText)
            let safeLocation = min(selectedRange.location, textView.string.count)
            textView.setSelectedRange(NSRange(location: safeLocation, length: 0))
        }
    }

    public final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditorView
        weak var textView: NSTextView?
        private var isProgrammaticChange = false

        init(parent: RichTextEditorView) {
            self.parent = parent
        }

        public func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            let newValue = tv.attributedString()
            if parent.attributedText != newValue {
                parent.attributedText = newValue
            }
        }
    }
}
