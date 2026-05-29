import SwiftUI
import AppKit

public struct PreviewContentView: View {
    let rootNode: ArchiveNode
    let archiveURL: URL
    let coordinator: ArchivePreviewCoordinator

    public init(
        rootNode: ArchiveNode,
        archiveURL: URL,
        coordinator: ArchivePreviewCoordinator
    ) {
        self.rootNode = rootNode
        self.archiveURL = archiveURL
        self.coordinator = coordinator
    }

    public var body: some View {
        MainView(
            rootNode: rootNode,
            archiveURL: archiveURL,
            coordinator: coordinator
        )
    }
}

struct ArchiveKeyboardMonitor: NSViewRepresentable {
    let onCopy: () -> Void
    let onNavigateUp: () -> Bool
    let onNavigateForward: () -> Bool

    func makeNSView(context: Context) -> ArchiveKeyboardMonitorView {
        let view = ArchiveKeyboardMonitorView()
        view.onCopy = onCopy
        view.onNavigateUp = onNavigateUp
        view.onNavigateForward = onNavigateForward
        return view
    }

    func updateNSView(_ nsView: ArchiveKeyboardMonitorView, context: Context) {
        nsView.onCopy = onCopy
        nsView.onNavigateUp = onNavigateUp
        nsView.onNavigateForward = onNavigateForward
    }
}

@MainActor
final class ArchiveKeyboardMonitorView: NSView {
    var onCopy: (() -> Void)?
    var onNavigateUp: (() -> Bool)?
    var onNavigateForward: (() -> Bool)?
    private var monitor: Any?

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        installMonitor()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if newWindow == nil {
            removeMonitor()
        }
    }

    private func installMonitor() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            guard event.window === self.window else { return event }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if flags.contains(.command),
               event.charactersIgnoringModifiers?.lowercased() == "c" {
                self.onCopy?()
                return nil
            }

            guard flags.isDisjoint(with: [.command, .option, .control]) else { return event }

            switch event.keyCode {
            case 123:
                if self.onNavigateUp?() == true { return nil }
            case 124:
                if self.onNavigateForward?() == true { return nil }
            default:
                break
            }
            return event
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
