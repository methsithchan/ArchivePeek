import Foundation

/// Errors that can occur during archive operations.
public enum ArchiveError: Error, LocalizedError {
    case openFailed(String)
    case readFailed(String)
    case extractionFailed(String)
    case entryNotFound(String)
    case destinationCreationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .openFailed(let msg):
            return "Failed to open archive: \(msg)"
        case .readFailed(let msg):
            return "Failed to read archive: \(msg)"
        case .extractionFailed(let msg):
            return "Extraction failed: \(msg)"
        case .entryNotFound(let path):
            return "File not found in archive: \(path)"
        case .destinationCreationFailed(let msg):
            return "Failed to create destination: \(msg)"
        }
    }
}

/// A Swift actor wrapper around C `libarchive` APIs, ensuring thread-safe, non-blocking archive reading and parsing.
public actor ArchiveReader {
    private let archiveURL: URL
    
    public init(archiveURL: URL) {
        self.archiveURL = archiveURL
    }
    
    /// Reads the archive headers stream-efficiently to build a hierarchical `ArchiveNode` tree.
    public func readTree() throws -> ArchiveNode {
        guard let a = archive_read_new() else {
            throw ArchiveError.openFailed("Could not initialize archive reader context")
        }
        
        defer {
            archive_read_close(a)
            archive_read_free(a)
        }
        
        archive_read_support_filter_all(a)
        archive_read_support_format_all(a)
        
        // Safely open the file using system filesystem representation
        let openResult = archiveURL.withUnsafeFileSystemRepresentation { fsPath -> Int32 in
            guard let fsPath = fsPath else { return -1 }
            return archive_read_open_filename(a, fsPath, 10240)
        }
        
        if openResult != 0 { // ARCHIVE_OK is 0
            let errorMsg = String(cString: archive_error_string(a))
            throw ArchiveError.openFailed(errorMsg)
        }
        
        // Mutable tree builder
        class MutableNode {
            let name: String
            var path: String
            var isDirectory: Bool
            var size: Int64
            var lastModified: Date?
            var children: [String: MutableNode] = [:]
            
            init(name: String, path: String, isDirectory: Bool, size: Int64, lastModified: Date? = nil) {
                self.name = name
                self.path = path
                self.isDirectory = isDirectory
                self.size = size
                self.lastModified = lastModified
            }
            
            func toImmutable() -> ArchiveNode {
                let childNodes = children.values.map { $0.toImmutable() }
                return ArchiveNode(
                    name: name,
                    path: path,
                    isDirectory: isDirectory,
                    size: size,
                    lastModified: lastModified,
                    children: childNodes
                )
            }
        }
        
        let root = MutableNode(name: "Root", path: "", isDirectory: true, size: 0)
        var entry: OpaquePointer? = nil
        
        while archive_read_next_header(a, &entry) == 0 { // ARCHIVE_OK is 0
            guard let entry = entry else { continue }
            
            guard let pathC = archive_entry_pathname(entry) else { continue }
            let rawPath = String(cString: pathC)
            
            // Clean up trailing and leading slashes to normalize path splits
            let cleanPath = rawPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if cleanPath.isEmpty { continue }
            
            let size = archive_entry_size(entry)
            let filetype = archive_entry_filetype(entry)
            // AE_IFDIR is 0040000 in octal (directory flag)
            let isDirectory = (filetype & 0o170000) == 0o040000
            
            let mtime = archive_entry_mtime(entry)
            let lastModified = mtime > 0 ? Date(timeIntervalSince1970: TimeInterval(mtime)) : nil
            
            let components = cleanPath.split(separator: "/").map(String.init)
            
            var current = root
            for (index, component) in components.enumerated() {
                let isLast = (index == components.count - 1)
                let currentRelativePath = components[0...index].joined(separator: "/")
                
                if let existing = current.children[component] {
                    if isLast {
                        existing.isDirectory = isDirectory
                        existing.size = size
                        existing.lastModified = lastModified
                    }
                    current = existing
                } else {
                    let nodeIsDir = isLast ? isDirectory : true
                    let nodeSize = isLast ? size : 0
                    let nodeDate = isLast ? lastModified : nil
                    
                    let newNode = MutableNode(
                        name: component,
                        path: currentRelativePath,
                        isDirectory: nodeIsDir,
                        size: nodeSize,
                        lastModified: nodeDate
                    )
                    current.children[component] = newNode
                    current = newNode
                }
            }
        }
        
        return root.toImmutable()
    }
    
    /// Extracts a specific file or directory from the archive to a destination URL on disk.
    public func extract(path: String, to destinationURL: URL) throws {
        guard let a = archive_read_new() else {
            throw ArchiveError.openFailed("Could not initialize archive reader context")
        }
        defer {
            archive_read_close(a)
            archive_read_free(a)
        }
        
        archive_read_support_filter_all(a)
        archive_read_support_format_all(a)
        
        let openResult = archiveURL.withUnsafeFileSystemRepresentation { fsPath -> Int32 in
            guard let fsPath = fsPath else { return -1 }
            return archive_read_open_filename(a, fsPath, 10240)
        }
        
        if openResult != 0 {
            let errorMsg = String(cString: archive_error_string(a))
            throw ArchiveError.openFailed(errorMsg)
        }
        
        // Clean target path
        let targetPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let extractsWholeArchive = targetPath.isEmpty
        
        var entry: OpaquePointer? = nil
        var found = false
        
        while archive_read_next_header(a, &entry) == 0 {
            guard let entry = entry else { continue }
            guard let pathC = archive_entry_pathname(entry) else { continue }
            let entryRawPath = String(cString: pathC)
            let entryCleanPath = entryRawPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            
            // Check if this entry is the target file or a child of the target directory
            let isExactMatch = !extractsWholeArchive && (entryCleanPath == targetPath)
            let isChildOfDirectory = extractsWholeArchive || entryCleanPath.hasPrefix(targetPath + "/")
            
            if isExactMatch || isChildOfDirectory {
                found = true
                
                let filetype = archive_entry_filetype(entry)
                let isEntryDirectory = (filetype & 0o170000) == 0o040000
                
                // Determine the local destination URL
                let relativePathPart: String
                if extractsWholeArchive {
                    relativePathPart = entryCleanPath
                } else if isChildOfDirectory {
                    // Extract relative path from the target directory parent
                    // e.g. targetPath = "dir", entryCleanPath = "dir/sub/file.txt" -> relativePathPart = "sub/file.txt"
                    let startIndex = entryCleanPath.index(entryCleanPath.startIndex, offsetBy: targetPath.count + 1)
                    relativePathPart = String(entryCleanPath[startIndex...])
                } else {
                    relativePathPart = ""
                }
                
                let targetDestinationURL = relativePathPart.isEmpty ? destinationURL : destinationURL.appendingPathComponent(relativePathPart)
                
                if isEntryDirectory {
                    try FileManager.default.createDirectory(at: targetDestinationURL, withIntermediateDirectories: true)
                } else {
                    // Ensure the parent directory exists
                    let parentDir = targetDestinationURL.deletingLastPathComponent()
                    try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
                    
                    if FileManager.default.fileExists(atPath: targetDestinationURL.path) {
                        try FileManager.default.removeItem(at: targetDestinationURL)
                    }
                    
                    // Create the destination file
                    if !FileManager.default.createFile(atPath: targetDestinationURL.path, contents: nil) {
                        throw ArchiveError.destinationCreationFailed("Could not create file: \(targetDestinationURL.path)")
                    }
                    
                    let fileHandle = try FileHandle(forWritingTo: targetDestinationURL)
                    defer {
                        try? fileHandle.close()
                    }
                    
                    // Read file data blocks and write them to disk
                    var buff: UnsafeRawPointer? = nil
                    var size: Int = 0
                    var offset: Int64 = 0
                    
                    while true {
                        let r = archive_read_data_block(a, &buff, &size, &offset)
                        if r == 1 { // ARCHIVE_EOF
                            break
                        }
                        if r < 0 {
                            let errorMsg = String(cString: archive_error_string(a))
                            throw ArchiveError.extractionFailed(errorMsg)
                        }
                        if let buff = buff, size > 0 {
                            let data = Data(bytes: buff, count: size)
                            try fileHandle.write(contentsOf: data)
                        }
                    }
                }
                
                // If it was a single file exact match, we can stop reading
                if isExactMatch && !isEntryDirectory {
                    break
                }
            }
        }
        
        if !found {
            throw ArchiveError.entryNotFound(path)
        }
    }
}
