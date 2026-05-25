import Foundation

/// Represents a node (file or directory) in the virtual file system tree parsed from an archive.
public final class ArchiveNode: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let size: Int64
    public let lastModified: Date?
    public let children: [ArchiveNode]
    
    public init(
        name: String,
        path: String,
        isDirectory: Bool,
        size: Int64,
        lastModified: Date? = nil,
        children: [ArchiveNode] = []
    ) {
        self.id = UUID()
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.lastModified = lastModified
        // Sort children: directories first, then files alphabetically (localized-aware)
        self.children = children.sorted {
            if $0.isDirectory != $1.isDirectory {
                return $0.isDirectory // Directories first
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
    
    /// Helper to check if the node has children
    public var hasChildren: Bool {
        !children.isEmpty
    }
    
    /// Recursive lookup for a node at a path relative to this node
    public func findNode(at relativePath: String) -> ArchiveNode? {
        let cleanPath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if cleanPath.isEmpty {
            return self
        }
        let components = cleanPath.split(separator: "/").map(String.init)
        return findNode(components: components)
    }
    
    private func findNode(components: [String]) -> ArchiveNode? {
        guard let first = components.first else { return self }
        guard let match = children.first(where: { $0.name == first }) else { return nil }
        if components.count == 1 {
            return match
        } else {
            return match.findNode(components: Array(components.dropFirst()))
        }
    }
}
