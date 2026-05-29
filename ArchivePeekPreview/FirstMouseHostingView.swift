import AppKit
import SwiftUI

/// NSHostingView that accepts the first mouse click without requiring the Quick Look window to be key first.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        super.mouseDown(with: event)
    }
}

/// Hosts SwiftUI content with first-mouse acceptance for Quick Look.
final class FirstMouseHostingController<Content: View>: NSHostingController<Content> {
    override init(rootView: Content) {
        super.init(rootView: rootView)
        view = FirstMouseHostingView(rootView: rootView)
    }

    @MainActor @preconcurrency required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
