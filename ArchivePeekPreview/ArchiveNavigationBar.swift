import AppKit
import SwiftUI

/// AppKit-backed nav buttons — SwiftUI borderless buttons lag ~1s in Quick Look
/// while macOS waits to detect double-clicks.
struct ArchiveNavigationBar: NSViewRepresentable {
    let canGoUp: Bool
    let canGoForward: Bool
    let onGoUp: () -> Void
    let onGoForward: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onGoUp: onGoUp, onGoForward: onGoForward)
    }

    func makeNSView(context: Context) -> NavBarContainer {
        let bar = NavBarContainer()
        bar.translatesAutoresizingMaskIntoConstraints = false

        let back = Self.makeButton(symbol: "chevron.left", tag: 0, coordinator: context.coordinator)
        let forward = Self.makeButton(symbol: "chevron.right", tag: 1, coordinator: context.coordinator)

        let stack = NSStackView(views: [back, forward])
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        bar.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 20),
            stack.topAnchor.constraint(equalTo: bar.topAnchor, constant: 4),
            back.widthAnchor.constraint(equalToConstant: 32),
            back.heightAnchor.constraint(equalToConstant: 28),
            forward.widthAnchor.constraint(equalToConstant: 32),
            forward.heightAnchor.constraint(equalToConstant: 28),
        ])

        context.coordinator.backButton = back
        context.coordinator.forwardButton = forward
        return bar
    }

    func updateNSView(_ bar: NavBarContainer, context: Context) {
        context.coordinator.onGoUp = onGoUp
        context.coordinator.onGoForward = onGoForward
        context.coordinator.backButton?.isEnabled = canGoUp
        context.coordinator.forwardButton?.isEnabled = canGoForward
    }

    private static func makeButton(symbol: String, tag: Int, coordinator: Coordinator) -> NSButton {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        let button = ImmediateNavButton(image: image ?? NSImage(), target: coordinator, action: #selector(Coordinator.buttonTapped(_:)))
        button.tag = tag
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        button.toolTip = tag == 0 ? "Go to enclosing folder (←)" : "Forward (→)"
        return button
    }

    /// Fixed-height container so SwiftUI doesn't stretch the nav bar to fill the window.
    final class NavBarContainer: NSView {
        override var isFlipped: Bool { true }

        override var intrinsicContentSize: NSSize {
            NSSize(width: NSView.noIntrinsicMetric, height: ArchivePreviewModel.navigationBarHeight)
        }
    }

    /// Fires its action on mouse-down so Quick Look doesn't wait for double-click detection.
    private final class ImmediateNavButton: NSButton {
        override func mouseDown(with event: NSEvent) {
            guard isEnabled, let target, let action else { return }
            NSApp.sendAction(action, to: target, from: self)
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var onGoUp: () -> Void
        var onGoForward: () -> Void
        weak var backButton: NSButton?
        weak var forwardButton: NSButton?

        init(onGoUp: @escaping () -> Void, onGoForward: @escaping () -> Void) {
            self.onGoUp = onGoUp
            self.onGoForward = onGoForward
        }

        @objc func buttonTapped(_ sender: NSButton) {
            switch sender.tag {
            case 0: onGoUp()
            case 1: onGoForward()
            default: break
            }
        }
    }
}

extension ArchiveNavigationBar {
    func archiveNavBarStyle() -> some View {
        frame(maxWidth: .infinity)
        .frame(height: ArchivePreviewModel.navigationBarHeight)
        .fixedSize(horizontal: false, vertical: true)
        .background(.bar)
    }
}
