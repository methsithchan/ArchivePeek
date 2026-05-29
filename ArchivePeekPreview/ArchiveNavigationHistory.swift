import Foundation

/// Forward navigation history stored as lightweight folder name paths.
@MainActor
struct ArchiveNavigationHistory {
    private var forwardStack: [[String]] = []

    var canGoForward: Bool { !forwardStack.isEmpty }

    mutating func pushForward(_ pathNames: [String]) {
        forwardStack.append(pathNames)
    }

    mutating func takeForward() -> [String]? {
        forwardStack.popLast()
    }

    mutating func clearForward() {
        forwardStack.removeAll()
    }
}

enum ArchivePathResolver {
    static func node(at pathNames: [String], from root: ArchiveNode) -> ArchiveNode {
        var node = root
        for name in pathNames {
            guard let next = node.children.first(where: { $0.name == name }) else { break }
            node = next
        }
        return node
    }

    static func nodes(from pathNames: [String], startingAt root: ArchiveNode) -> [ArchiveNode] {
        var stack: [ArchiveNode] = []
        var node = root
        for name in pathNames {
            guard let next = node.children.first(where: { $0.name == name }) else { break }
            stack.append(next)
            node = next
        }
        return stack
    }
}
