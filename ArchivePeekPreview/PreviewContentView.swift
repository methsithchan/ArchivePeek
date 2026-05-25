import SwiftUI
import AppKit

public struct PreviewContentView: View {
    let rootNode: ArchiveNode
    let archiveURL: URL
    
    // Navigation State
    @State private var pathStack: [ArchiveNode] = []
    @State private var backStack: [[ArchiveNode]] = []
    @State private var forwardStack: [[ArchiveNode]] = []
    @State private var expandedNodeIds: Set<UUID> = []
    
    // UI State
    @State private var selectedNodeId: UUID? = nil
    @State private var showInspector: Bool = true
    @State private var searchText: String = ""
    @State private var bannerMessage: String? = nil
    @State private var bannerIsError: Bool = false
    @State private var pasteboardItems: [URL] = []
    
    public init(rootNode: ArchiveNode, archiveURL: URL) {
        self.rootNode = rootNode
        self.archiveURL = archiveURL
    }
    
    // Resolved Navigation node
    private var currentNode: ArchiveNode {
        pathStack.last ?? rootNode
    }
    
    // Filtered children based on search and current folder
    private var displayedNodes: [ArchiveNode] {
        if searchText.isEmpty {
            return currentNode.children
        } else {
            // Recursive search across the entire tree
            return searchNodes(root: rootNode, query: searchText)
        }
    }
    
    // Selected node metadata
    private var selectedNode: ArchiveNode? {
        guard let id = selectedNodeId else { return nil }
        return findNodeInList(id: id, root: rootNode)
    }
    
    private var titleText: String {
        pathStack.last?.name ?? archiveURL.deletingPathExtension().lastPathComponent
    }
    
    private var visibleRows: [ArchiveRow] {
        if !searchText.isEmpty {
            return displayedNodes.map { ArchiveRow(node: $0, depth: 0) }
        }
        return flattenedRows(nodes: currentNode.children, depth: 0)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Banner Notification
            if let bannerMessage = bannerMessage {
                HStack {
                    Image(systemName: bannerIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundColor(bannerIsError ? .red : .green)
                    Text(bannerMessage)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: { self.bannerMessage = nil }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: bannerMessage)
            }

            VStack(spacing: 0) {
                ArchiveTableHeader()
                
                if visibleRows.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: searchText.isEmpty ? "folder.badge.questionmark" : "magnifyingglass")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "Empty Directory" : "No results found")
                            .foregroundColor(.secondary)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(selection: $selectedNodeId) {
                        ForEach(visibleRows) { row in
                            ArchiveTableRow(
                                node: row.node,
                                depth: row.depth,
                                isExpanded: expandedNodeIds.contains(row.node.id),
                                searchText: searchText,
                                onToggle: { toggleExpansion(for: row.node) }
                            )
                            .tag(row.node.id)
                            .contextMenu {
                                Button("Extract Selected...") {
                                    extractWithSavePanel(node: row.node)
                                }
                                Button("Copy") {
                                    copyItemToPasteboard(node: row.node)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                Divider()
                StatusBarView(
                    archiveURL: archiveURL,
                    pathStack: pathStack,
                    selectedNode: selectedNode,
                    totalCount: currentNode.children.count,
                    onNavigateUp: navigateUp,
                    onNavigateToRoot: navigateToRoot,
                    onNavigateToBreadcrumb: navigateToBreadcrumb(index:)
                )
            }
            .transaction { transaction in
                transaction.animation = nil
            }
        }
        .frame(minWidth: 700, minHeight: 450)
        .background(VisualEffectView(material: .windowBackground, blendingMode: .withinWindow))
        .background(
            CopyKeyboardMonitor {
                guard let node = selectedNode else { return }
                copyItemToPasteboard(node: node)
            }
        )
        .onCopyCommand {
            guard let node = selectedNode else { return [] }
            copyItemToPasteboard(node: node)
            return []
        }
    }
    
    private func toggleExpansion(for node: ArchiveNode) {
        guard node.isDirectory else { return }
        if expandedNodeIds.contains(node.id) {
            expandedNodeIds.remove(node.id)
        } else {
            expandedNodeIds.insert(node.id)
        }
    }
    
    private func flattenedRows(nodes: [ArchiveNode], depth: Int) -> [ArchiveRow] {
        nodes.flatMap { node -> [ArchiveRow] in
            var rows = [ArchiveRow(node: node, depth: depth)]
            if node.isDirectory && expandedNodeIds.contains(node.id) {
                rows.append(contentsOf: flattenedRows(nodes: node.children, depth: depth + 1))
            }
            return rows
        }
    }
    
    // MARK: - Navigation Logic
    
    private func diveIntoDirectory(_ node: ArchiveNode) {
        withoutAnimation {
            backStack.append(pathStack)
            forwardStack.removeAll()
            pathStack.append(node)
            selectedNodeId = nil
            expandedNodeIds.removeAll()
        }
    }
    
    private func navigateBack() {
        guard !backStack.isEmpty else { return }
        forwardStack.append(pathStack)
        pathStack = backStack.removeLast()
        selectedNodeId = nil
    }
    
    private func navigateForward() {
        guard !forwardStack.isEmpty else { return }
        backStack.append(pathStack)
        pathStack = forwardStack.removeLast()
        selectedNodeId = nil
    }
    
    private func navigateToRoot() {
        guard !pathStack.isEmpty else { return }
        withoutAnimation {
            backStack.append(pathStack)
            forwardStack.removeAll()
            pathStack.removeAll()
            selectedNodeId = nil
            expandedNodeIds.removeAll()
        }
    }
    
    private func navigateUp() {
        guard !pathStack.isEmpty else { return }
        withoutAnimation {
            backStack.append(pathStack)
            forwardStack.removeAll()
            pathStack.removeLast()
            selectedNodeId = nil
            expandedNodeIds.removeAll()
        }
    }
    
    private func navigateToBreadcrumb(index: Int) {
        guard index < pathStack.count - 1 else { return }
        withoutAnimation {
            backStack.append(pathStack)
            forwardStack.removeAll()
            if index == -1 {
                pathStack.removeAll()
            } else {
                pathStack = Array(pathStack[0...index])
            }
            selectedNodeId = nil
            expandedNodeIds.removeAll()
        }
    }
    
    private func withoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction, updates)
    }
    
    // MARK: - Helper Lookup Functions
    
    private func searchNodes(root: ArchiveNode, query: String) -> [ArchiveNode] {
        var results: [ArchiveNode] = []
        func traverse(_ node: ArchiveNode) {
            if !node.name.isEmpty && node.name.localizedCaseInsensitiveContains(query) {
                results.append(node)
            }
            for child in node.children {
                traverse(child)
            }
        }
        traverse(root)
        return results
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
    
    // MARK: - Extraction Banner & Save Panel
    
    private func showBanner(message: String, isError: Bool = false) {
        bannerIsError = isError
        bannerMessage = message
        
        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            if self.bannerMessage == message {
                withAnimation {
                    self.bannerMessage = nil
                }
            }
        }
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
    
    private func extractWithSavePanel(node: ArchiveNode) {
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
                        self.showBanner(message: "Extracted '\(node.name)' successfully!")
                    }
                } catch {
                    await MainActor.run {
                        self.showBanner(message: "Extraction failed: \(error.localizedDescription)", isError: true)
                    }
                }
            }
        }
    }
}

// MARK: - Archive Table Components

struct ArchiveRow: Identifiable {
    let node: ArchiveNode
    let depth: Int
    
    var id: UUID {
        node.id
    }
}

struct ArchiveTableHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            tableHeaderText("Name")
                .frame(maxWidth: .infinity, alignment: .leading)
            tableHeaderText("Date Modified")
                .frame(width: 190, alignment: .leading)
            tableHeaderText("Size")
                .frame(width: 96, alignment: .leading)
            tableHeaderText("Kind")
                .frame(width: 150, alignment: .leading)
        }
        .font(.caption)
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .frame(height: 26)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.55))
    }
    
    private func tableHeaderText(_ text: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .foregroundColor(.secondary)
            Spacer(minLength: 0)
            Rectangle()
                .fill(Color(NSColor.separatorColor).opacity(0.55))
                .frame(width: 1)
        }
    }
}

struct ArchiveTableRow: View {
    let node: ArchiveNode
    let depth: Int
    let isExpanded: Bool
    let searchText: String
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Spacer()
                    .frame(width: CGFloat(depth) * 18)
                
                if node.isDirectory && searchText.isEmpty {
                    Button(action: onToggle) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 18)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(width: 12)
                }
                
                Image(systemName: iconName(for: node))
                    .font(.system(size: 15))
                    .foregroundColor(node.isDirectory ? .accentColor : .secondary)
                    .frame(width: 18)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(node.name)
                        .lineLimit(1)
                    if !searchText.isEmpty {
                        Text(node.path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(modifiedDate(for: node))
                .foregroundColor(.secondary)
                .frame(width: 190, alignment: .leading)
            
            Text(sizeText(for: node))
                .foregroundColor(.secondary)
                .frame(width: 96, alignment: .leading)
            
            Text(kindText(for: node))
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 10)
        .frame(height: 22)
    }
    
    private func modifiedDate(for node: ArchiveNode) -> String {
        guard let date = node.lastModified else { return "--" }
        return rowDateFormatter.string(from: date)
    }
    
    private func sizeText(for node: ArchiveNode) -> String {
        if node.isDirectory {
            return node.children.isEmpty ? "--" : "\(node.children.count) items"
        }
        return ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file)
    }
    
    private func kindText(for node: ArchiveNode) -> String {
        if node.isDirectory { return "Folder" }
        let ext = URL(fileURLWithPath: node.path).pathExtension.uppercased()
        if ext.isEmpty { return "Document" }
        return "\(ext) Document"
    }
    
    private func iconName(for node: ArchiveNode) -> String {
        if node.isDirectory { return "folder.fill" }
        switch URL(fileURLWithPath: node.path).pathExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "heic", "tiff", "webp":
            return "photo"
        case "mp3", "m4a", "wav", "flac":
            return "music.note"
        case "mp4", "mkv", "mov", "avi":
            return "film"
        case "pdf":
            return "doc.richtext"
        case "zip", "tar", "gz", "tgz", "rar", "7z":
            return "archivebox"
        default:
            return "doc"
        }
    }
    
    private var rowDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct StatusBarView: View {
    let archiveURL: URL
    let pathStack: [ArchiveNode]
    let selectedNode: ArchiveNode?
    let totalCount: Int
    let onNavigateUp: () -> Void
    let onNavigateToRoot: () -> Void
    let onNavigateToBreadcrumb: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: onNavigateUp) {
                Image(systemName: "chevron.left")
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .disabled(pathStack.isEmpty)
            .help("Back to parent folder")
            
            Image(systemName: "internaldrive")
                .foregroundColor(.secondary)
            
            Button(action: onNavigateToRoot) {
                Text(archiveURL.lastPathComponent)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .foregroundColor(pathStack.isEmpty ? .secondary : .primary)
            .disabled(pathStack.isEmpty)
            
            ForEach(Array(pathStack.enumerated()), id: \.element.id) { index, node in
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Button(action: { onNavigateToBreadcrumb(index) }) {
                    Text(node.name)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .foregroundColor(index == pathStack.count - 1 ? .secondary : .primary)
                .disabled(index == pathStack.count - 1)
            }
            
            Spacer()
            
            Text(selectedNode?.name ?? "\(totalCount) items")
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

// MARK: - File Row Component

struct FileRowView: View {
    let node: ArchiveNode
    let searchText: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName(for: node))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundColor(node.isDirectory ? .secondary : .primary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if !searchText.isEmpty {
                    Text(node.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if !node.isDirectory {
                Text(ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("\(node.children.count) items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconName(for node: ArchiveNode) -> String {
        if node.isDirectory {
            return "folder.fill"
        }
        
        let pathExtension = URL(fileURLWithPath: node.path).pathExtension.lowercased()
        switch pathExtension {
        case "jpg", "jpeg", "png", "gif", "heic", "tiff", "webp":
            return "doc.richtext"
        case "mp3", "m4a", "wav", "flac":
            return "music.note.list"
        case "mp4", "mkv", "mov", "avi":
            return "video"
        case "pdf":
            return "doc.text.fill"
        case "zip", "tar", "gz", "tgz", "rar", "7z":
            return "doc.zipperaction"
        case "swift", "h", "m", "c", "cpp", "py", "js", "html", "css", "json", "yml", "yaml":
            return "scroll.fill"
        default:
            return "doc"
        }
    }
}

// MARK: - Sidebar Inspector Component

struct InspectorView: View {
    let node: ArchiveNode?
    let archiveURL: URL
    let onExtract: (ArchiveNode) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if let node = node {
                VStack(spacing: 12) {
                    // Icon and Header
                    Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding(.top, 24)
                    
                    Text(node.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 16)
                    
                    Text(node.isDirectory ? "Folder" : "File")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Divider()
                
                // Metadata Details
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(label: "Relative Path", value: node.path)
                    
                    if !node.isDirectory {
                        detailRow(label: "Uncompressed Size", value: ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file))
                    }
                    
                    if let date = node.lastModified {
                        detailRow(label: "Last Modified", value: dateFormatter.string(from: date))
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Primary extraction action button
                Button(action: { onExtract(node) }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Extract Selected...")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                
            } else {
                // Empty state (archive details)
                VStack(spacing: 12) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding(.top, 24)
                    
                    Text(archiveURL.lastPathComponent)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    Text("Select a file or directory to inspect its details and extract it.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                Spacer()
            }
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.bold)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Visual Effects View (NSVisualEffectView Wrapper)

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct CopyKeyboardMonitor: NSViewRepresentable {
    let onCopy: () -> Void

    func makeNSView(context: Context) -> CopyKeyboardMonitorView {
        let view = CopyKeyboardMonitorView()
        view.onCopy = onCopy
        return view
    }

    func updateNSView(_ nsView: CopyKeyboardMonitorView, context: Context) {
        nsView.onCopy = onCopy
    }
}

@MainActor
final class CopyKeyboardMonitorView: NSView {
    var onCopy: (() -> Void)?
    private var monitor: Any?

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
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command) else { return event }
            guard event.charactersIgnoringModifiers?.lowercased() == "c" else { return event }

            self.onCopy?()
            return nil
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
