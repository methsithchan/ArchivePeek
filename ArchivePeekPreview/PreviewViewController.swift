import Cocoa
import QuickLookUI
import SwiftUI

/// Principal class of the ArchivePeek Quick Look Extension, bridging macOS QuickLookUI with SwiftUI.
public class PreviewViewController: NSViewController, @preconcurrency QLPreviewingController {
    
    private var hostingController: NSHostingController<PreviewContentView>?
    private var doubleClickMonitor: Any?

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
                // Read the archive tree asynchronously via our libarchive bridge actor
                let reader = ArchiveReader(archiveURL: url)
                let rootNode = try await reader.readTree()
                
                await MainActor.run {
                    let contentView = PreviewContentView(rootNode: rootNode, archiveURL: url)
                    let hosting = NSHostingController(rootView: contentView)
                    
                    // Clear previous hosting controller if reuse occurs
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
                    // Show error fallback view if archive parsing fails
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
                    self.installDoubleClickMonitor()
                    
                    handler(error)
                }
            }
        }
    }

    private func installDoubleClickMonitor() {
        removeDoubleClickMonitor()

        doubleClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self else { return event }
            guard event.clickCount >= 2 else { return event }
            guard event.window === self.view.window else { return event }

            return nil
        }
    }

    private func removeDoubleClickMonitor() {
        if let doubleClickMonitor {
            NSEvent.removeMonitor(doubleClickMonitor)
            self.doubleClickMonitor = nil
        }
    }
}

/// Fallback view displayed when ArchivePeek fails to parse an archive.
struct ErrorContentView: View {
    let errorDescription: String
    let fileURL: URL
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.red)
            
            Text("Failed to Preview Archive")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(fileURL.lastPathComponent)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(errorDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectView(material: .windowBackground, blendingMode: .withinWindow))
    }
}
