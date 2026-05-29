import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum ArchiveNodeIcon {
    private nonisolated(unsafe) static let cache = NSCache<NSString, NSImage>()

    static func nsImage(for node: ArchiveNode) -> NSImage {
        let cacheKey: NSString
        if node.isDirectory {
            cacheKey = "folder" as NSString
        } else {
            let ext = URL(fileURLWithPath: node.path).pathExtension.lowercased()
            cacheKey = (ext.isEmpty ? "data" : ext) as NSString
        }

        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let image: NSImage
        if node.isDirectory {
            image = NSWorkspace.shared.icon(for: .folder)
        } else {
            let ext = URL(fileURLWithPath: node.path).pathExtension
            if !ext.isEmpty, let type = UTType(filenameExtension: ext) {
                image = NSWorkspace.shared.icon(for: type)
            } else {
                image = NSWorkspace.shared.icon(for: .data)
            }
        }

        cache.setObject(image, forKey: cacheKey)
        return image
    }

    static func nsImage(forArchiveAt url: URL) -> NSImage {
        let cacheKey = "archive:\(url.pathExtension.lowercased())" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }
        let image = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(image, forKey: cacheKey)
        return image
    }
}

struct ArchiveFileIcon: View {
    let nsImage: NSImage
    var size: CGFloat = 32

    init(node: ArchiveNode, size: CGFloat = 32) {
        self.nsImage = ArchiveNodeIcon.nsImage(for: node)
        self.size = size
    }

    init(archiveURL: URL, size: CGFloat = 32) {
        self.nsImage = ArchiveNodeIcon.nsImage(forArchiveAt: archiveURL)
        self.size = size
    }

    init(contentType: UTType, size: CGFloat = 32) {
        self.nsImage = NSWorkspace.shared.icon(for: contentType)
        self.size = size
    }

    var body: some View {
        Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}

struct ArchiveFileLabel: View {
    let title: String
    let node: ArchiveNode
    var iconSize: CGFloat = 16

    var body: some View {
        Label {
            Text(title)
        } icon: {
            ArchiveFileIcon(node: node, size: iconSize)
        }
    }
}
