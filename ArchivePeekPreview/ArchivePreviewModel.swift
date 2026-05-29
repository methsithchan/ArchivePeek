import AppKit
import SwiftUI

/// Shared preview state wired to Quick Look's event monitor and SwiftUI views.
@MainActor
final class ArchivePreviewModel: ObservableObject {
    let rootNode: ArchiveNode
    let archiveURL: URL

    @Published var pathStack: [ArchiveNode] = []
    @Published var selectedNodeIds: Set<UUID> = []
    @Published var bannerMessage: String?
    @Published var headerHeight: CGFloat = ArchivePreviewModel.navigationBarHeight

    private var backStack: [[ArchiveNode]] = []
    private var forwardStack: [[ArchiveNode]] = []
    private var pasteboardItems: [URL] = []
    private var lastSelectedNodeId: UUID?
    private var lastSelectionTime: Date = .distantPast
    private var lastActivateTime: Date = .distantPast

    /// Height of the in-window nav bar in SwiftUI coordinates (top-left origin).
    static let navigationBarHeight: CGFloat = 36
    static let bannerHeight: CGFloat = 28

    init(rootNode: ArchiveNode, archiveURL: URL) {
        self.rootNode = rootNode
        self.archiveURL = archiveURL
    }

    var archiveDisplayName: String {
        archiveURL.deletingPathExtension().lastPathComponent
    }

    var currentNode: ArchiveNode {
        pathStack.last ?? rootNode
    }

    var displayedNodes: [ArchiveNode] {
        currentNode.children
    }

    var canGoUp: Bool { !pathStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }

    var contentTopInset: CGFloat {
        headerHeight
    }

    func noteSelection() {
        if selectedNodeIds.count == 1, let id = selectedNodeIds.first {
            lastSelectedNodeId = id
            lastSelectionTime = Date()
        }
    }

    func selectNode(_ node: ArchiveNode, extendSelection: Bool) {
        if extendSelection {
            if selectedNodeIds.contains(node.id) {
                selectedNodeIds.remove(node.id)
            } else {
                selectedNodeIds.insert(node.id)
            }
        } else {
            selectedNodeIds = [node.id]
        }
        lastSelectedNodeId = node.id
        lastSelectionTime = Date()
    }

    func activate(_ node: ArchiveNode) {
        let now = Date()
        guard now.timeIntervalSince(lastActivateTime) > 0.35 else { return }
        lastActivateTime = now

        if node.isDirectory {
            openNode(node)
        } else {
            extractWithSavePanel(node: node)
        }
    }

    /// Called from Quick Look's mouse monitor — always blocks archive-wide extract when in content.
    func handleDoubleClick(at point: CGPoint) {
        guard point.y >= contentTopInset else { return }

        guard Date().timeIntervalSince(lastSelectionTime) < 0.75 else { return }

        let candidateID = selectedNodeIds.first ?? lastSelectedNodeId
        guard let candidateID,
              let node = displayedNodes.first(where: { $0.id == candidateID }) else {
            return
        }

        activate(node)
    }

    func openNode(_ node: ArchiveNode) {
        guard node.isDirectory else { return }
        if node.id == currentNode.id { return }
        diveIntoDirectory(node)
    }

    func navigateUp() {
        guard !pathStack.isEmpty else { return }
        withoutAnimation {
            backStack.append(pathStack)
            forwardStack.removeAll()
            pathStack.removeLast()
            selectedNodeIds.removeAll()
            lastSelectedNodeId = nil
        }
    }

    func navigateForward() {
        guard !forwardStack.isEmpty else { return }
        withoutAnimation {
            backStack.append(pathStack)
            pathStack = forwardStack.removeLast()
            selectedNodeIds.removeAll()
            lastSelectedNodeId = nil
        }
    }

    func navigateUpIfPossible() -> Bool {
        guard canGoUp else { return false }
        navigateUp()
        return true
    }

    func navigateForwardIfPossible() -> Bool {
        guard canGoForward else { return false }
        navigateForward()
        return true
    }

    func copySelectedItems() {
        for id in selectedNodeIds {
            if let node = findNodeInList(id: id, root: rootNode) {
                copyItemToPasteboard(node: node)
            }
        }
    }

    private func diveIntoDirectory(_ node: ArchiveNode) {
        withoutAnimation {
            backStack.append(pathStack)
            forwardStack.removeAll()
            pathStack.append(node)
            selectedNodeIds.removeAll()
            lastSelectedNodeId = nil
        }
    }

    private func withoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction, updates)
    }

    private func findNodeInList(id: UUID, root: ArchiveNode) -> ArchiveNode? {
        if root.id == id { return root }
        for child in root.children {
            if let match = findNodeInList(id: id, root: child) {
                return match
            }
        }
        return nil
    }

    private func showBanner(message: String, isError: Bool = false) {
        _ = isError
        bannerMessage = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self, self.bannerMessage == message else { return }
            self.bannerMessage = nil
        }
    }

    func copyNode(_ node: ArchiveNode) {
        copyItemToPasteboard(node: node)
    }

    private func copyItemToPasteboard(node: ArchiveNode) {
        showBanner(message: "Preparing '\(node.name)' for paste...")

        Task {
            do {
                let stagingRoot = FileManager.default.temporaryDirectory
                    .appendingPathComponent("ArchivePeekPasteboard", isDirectory: true)
                    .appendingPathComponent(UUID().uuidString, isDirectory: true)
                try FileManager.default.createDirectory(at: stagingRoot, withIntermediateDirectories: true)

                let itemURL = stagingRoot.appendingPathComponent(node.name, isDirectory: node.isDirectory)
                let reader = ArchiveReader(archiveURL: archiveURL)
                try await reader.extract(path: node.path, to: itemURL)

                await MainActor.run {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    _ = pasteboard.writeObjects([itemURL as NSURL])
                    pasteboard.setPropertyList(
                        [itemURL.path],
                        forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")
                    )
                    pasteboard.setString(itemURL.absoluteString, forType: .fileURL)
                    pasteboard.setString(itemURL.path, forType: .string)

                    pasteboardItems.append(stagingRoot)
                    if pasteboardItems.count > 8 {
                        let oldItems = Array(pasteboardItems.prefix(pasteboardItems.count - 8))
                        pasteboardItems.removeFirst(pasteboardItems.count - 8)
                        oldItems.forEach { try? FileManager.default.removeItem(at: $0) }
                    }

                    showBanner(message: "Copied '\(node.name)'")
                }
            } catch {
                await MainActor.run {
                    showBanner(message: "Copy failed: \(error.localizedDescription)", isError: true)
                }
            }
        }
    }

    func extractWithSavePanel(node: ArchiveNode) {
        Task { @MainActor in
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = node.name
            savePanel.prompt = "Extract"
            savePanel.message = "Choose destination to extract '\(node.name)'"
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            savePanel.level = .modalPanel

            let response = savePanel.runModal()
            guard response == .OK, let destinationURL = savePanel.url else { return }

            Task {
                do {
                    let reader = ArchiveReader(archiveURL: archiveURL)
                    try await reader.extract(path: node.path, to: destinationURL)
                    await MainActor.run {
                        showBanner(message: "Extracted '\(node.name)' successfully!")
                    }
                } catch {
                    await MainActor.run {
                        showBanner(message: "Extraction failed: \(error.localizedDescription)", isError: true)
                    }
                }
            }
        }
    }
}
