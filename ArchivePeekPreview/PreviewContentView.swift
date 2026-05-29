import SwiftUI

public struct PreviewContentView: View {
    let rootNode: ArchiveNode
    let archiveURL: URL
    let coordinator: ArchivePreviewCoordinator

    public init(
        rootNode: ArchiveNode,
        archiveURL: URL,
        coordinator: ArchivePreviewCoordinator
    ) {
        self.rootNode = rootNode
        self.archiveURL = archiveURL
        self.coordinator = coordinator
    }

    public var body: some View {
        MainView(
            rootNode: rootNode,
            archiveURL: archiveURL,
            coordinator: coordinator
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
