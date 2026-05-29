import Cocoa
import QuickLookUI
import SwiftUI

/// Principal class of the ArchivePeek Quick Look Extension, bridging macOS QuickLookUI with SwiftUI.
public class PreviewViewController: NSViewController, @preconcurrency QLPreviewingController {

    private var hostingController: NSHostingController<PreviewContentView>?
    private var rootView: ArchivePreviewRootView?
    private var navBar: ArchiveAppKitNavBar?
    private var doubleClickUpMonitor: Any?
    private var keyDownMonitor: Any?
    private let coordinator = ArchivePreviewCoordinator()

    public override func viewWillDisappear() {
        super.viewWillDisappear()
        removeDoubleClickMonitor()
        removeKeyDownMonitor()
    }

    public override func loadView() {
        let containerView = NSView()
        containerView.autoresizingMask = [.width, .height]
        self.view = containerView
    }

    /// Prepares the preview view controller with the target archive URL. Called by the macOS Quick Look server.
    public func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        coordinator.onModelDidChange = { [weak self] model in
            guard let self else { return }
            self.navBar?.attach(coordinator: self.coordinator)
            self.bindNavBar(to: model)
        }

        Task {
            do {
                let reader = ArchiveReader(archiveURL: url)
                let rootNode = try await reader.readTree()

                await MainActor.run {
                    self.installPreview(
                        PreviewContentView(
                            rootNode: rootNode,
                            archiveURL: url,
                            coordinator: self.coordinator
                        )
                    )
                    handler(nil)
                }
            } catch {
                await MainActor.run {
                    self.installError(
                        ErrorContentView(errorDescription: error.localizedDescription, fileURL: url)
                    )
                    handler(error)
                }
            }
        }
    }

    private func installPreview(_ content: PreviewContentView) {
        tearDownContent()

        let hosting = NSHostingController(rootView: content)
        hosting.safeAreaRegions = []

        let nav = ArchiveAppKitNavBar(coordinator: coordinator)
        let root = ArchivePreviewRootView(navBar: nav, contentView: hosting.view)
        root.translatesAutoresizingMaskIntoConstraints = false

        addChild(hosting)
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.topAnchor),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        hostingController = hosting
        rootView = root
        navBar = nav

        bindNavBar(to: coordinator.previewModel)
        installDoubleClickMonitor()
        installKeyDownMonitor()
    }

    private func installError(_ errorView: ErrorContentView) {
        tearDownContent()

        let hosting = NSHostingController(rootView: errorView)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hosting)
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func tearDownContent() {
        removeDoubleClickMonitor()
        removeKeyDownMonitor()

        if let hostingController {
            hostingController.view.removeFromSuperview()
            hostingController.removeFromParent()
            self.hostingController = nil
        }

        rootView?.removeFromSuperview()
        rootView = nil
        navBar = nil

        view.subviews.forEach { $0.removeFromSuperview() }
        children.forEach { $0.removeFromParent() }
    }

    private func bindNavBar(to model: ArchivePreviewModel?) {
        navBar?.updateState()
        guard let model else { return }

        model.onNavigationStateChanged = { [weak self] in
            self?.navBar?.updateState()
        }
    }

    private func installKeyDownMonitor() {
        removeKeyDownMonitor()

        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            guard event.window === self.view.window else { return event }
            guard let model = self.coordinator.previewModel else { return event }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if flags.contains(.command),
               event.charactersIgnoringModifiers?.lowercased() == "c" {
                model.copySelectedItems()
                return nil
            }

            guard flags.isDisjoint(with: [.command, .option, .control]) else { return event }

            switch event.keyCode {
            case 123:
                if model.navigateUpIfPossible() { return nil }
            case 124:
                if model.navigateForwardIfPossible() { return nil }
            default:
                break
            }
            return event
        }
    }

    private func removeKeyDownMonitor() {
        if let keyDownMonitor {
            NSEvent.removeMonitor(keyDownMonitor)
            self.keyDownMonitor = nil
        }
    }

    private func installDoubleClickMonitor() {
        removeDoubleClickMonitor()

        // Mouse-up only. A mouse-down monitor runs on every click in the window and makes nav feel laggy.
        doubleClickUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            guard event.clickCount >= 2 else { return event }
            guard let self else { return event }
            guard event.window === self.view.window else { return event }
            guard let rootView = self.rootView else { return event }

            let rootLocal = rootView.convert(event.locationInWindow, from: nil)
            if rootView.navBar.frame.contains(rootLocal) { return event }

            guard let contentView = self.hostingController?.view else { return event }

            let local = contentView.convert(event.locationInWindow, from: nil)
            guard contentView.bounds.contains(local) else { return event }

            self.coordinator.previewModel?.handleDoubleClick(
                at: Self.swiftUIPoint(in: contentView, windowLocation: event.locationInWindow)
            )
            return nil
        }
    }

    private func removeDoubleClickMonitor() {
        if let doubleClickUpMonitor {
            NSEvent.removeMonitor(doubleClickUpMonitor)
            self.doubleClickUpMonitor = nil
        }
    }

    /// Converts window coordinates to SwiftUI-style coordinates (origin at top-left of the hosting view).
    private static func swiftUIPoint(in view: NSView, windowLocation: NSPoint) -> CGPoint {
        let local = view.convert(windowLocation, from: nil)
        if view.isFlipped {
            return CGPoint(x: local.x, y: local.y)
        }
        return CGPoint(x: local.x, y: view.bounds.height - local.y)
    }
}

/// Fallback view displayed when ArchivePeek fails to parse an archive.
struct ErrorContentView: View {
    let errorDescription: String
    let fileURL: URL

    var body: some View {
        ContentUnavailableView {
            Label("Failed to Preview Archive", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text("\(fileURL.lastPathComponent)\n\(errorDescription)")
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.windowBackground)
    }
}
