import CoreGraphics
import Foundation

/// Bridges Quick Look's event monitor with preview state.
@MainActor
public final class ArchivePreviewCoordinator {
    weak var previewModel: ArchivePreviewModel?

    public init() {}
}
