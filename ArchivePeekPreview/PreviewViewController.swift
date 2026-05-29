import Cocoa
import QuickLookUI
import SwiftUI

/// Principal class of the ArchivePeek Quick Look Extension, bridging macOS QuickLookUI with SwiftUI.
public class PreviewViewController: NSViewController, @preconcurrency QLPreviewingController {

    private var hostingController: NSHostingController<PreviewContentView>?
    private var doubleClickMonitor: Any?
    private let coordinator = ArchivePreviewCoordinator()

    public override func viewWillDisappear() {
        super.viewWillDisappear()
        removeDoubleClickMonitor()
    }

    public override func loadView() {
        let containerView = NSView()
        containerView.autoresizingMask = [.width, .height]
        self.view = containerView
    }

    /// Prepares the preview view controller with the target archive URL. Called by the macOS Quick Look server.
    public func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        Task {
            do {
                let reader = ArchiveReader(archiveURL: url)
                let rootNode = try await reader.readTree()

                await MainActor.run {
                    let contentView = PreviewContentView(
                        rootNode: rootNode,
                        archiveURL: url,
                        coordinator: coordinator
                    )
                    let hosting = NSHostingController(rootView: contentView)

                    if let previous = self.hostingController {
                        previous.view.removeFromSuperview()
                        previous.removeFromParent()
                    }

                    self.hostingController = hosting
                    self.addChild(hosting)

                    hosting.view.frame = self.view.bounds
                    hosting.view.autoresizingMask = [.width, .height]
                    self.view.addSubview(hosting.view)
                    self.installDoubleClickMonitor()

                    handler(nil)
                }
            } catch {
                await MainActor.run {
                    let errorView = ErrorContentView(errorDescription: error.localizedDescription, fileURL: url)
                    let errorHosting = NSHostingController(rootView: errorView)

                    if let previous = self.hostingController {
                        previous.view.removeFromSuperview()
                        previous.removeFromParent()
                    }

                    self.addChild(errorHosting)
                    errorHosting.view.frame = self.view.bounds
                    errorHosting.view.autoresizingMask = [.width, .height]
                    self.view.addSubview(errorHosting.view)

                    handler(error)
                }
            }
        }
    }

    private func installDoubleClickMonitor() {
        removeDoubleClickMonitor()

        // Intercept on mouse-up so single clicks (including nav buttons) are not delayed.
        doubleClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            guard let self else { return event }
            guard event.window === self.view.window else { return event }
            guard event.clickCount >= 2 else { return event }
            guard let hostingView = self.hostingController?.view else { return event }

            let location = Self.swiftUIPoint(in: hostingView, windowLocation: event.locationInWindow)
            let topInset = self.coordinator.previewModel?.contentTopInset ?? ArchivePreviewModel.navigationBarHeight

            // Never intercept clicks in the header (nav bar + banner).
            guard location.y >= topInset else { return event }

            self.coordinator.previewModel?.handleDoubleClick(at: location)
            return nil
        }
    }

    private func removeDoubleClickMonitor() {
        if let doubleClickMonitor {
            NSEvent.removeMonitor(doubleClickMonitor)
            self.doubleClickMonitor = nil
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
