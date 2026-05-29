import SwiftUI

/// Icon grid isolated from header updates. Only re-renders when folder contents or selection change.
struct ArchiveFolderPane: View {
    @ObservedObject var model: ArchivePreviewModel

    var body: some View {
        ArchiveIconView(
            nodes: model.displayedNodes,
            selection: model.selectedNodeIds,
            onSelect: model.selectNode(_:extendSelection:),
            onActivate: model.activate(_:),
            onOpen: model.openNode(_:),
            onCopy: model.copyNode(_:),
            onExtract: model.extractWithSavePanel(node:)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background(.windowBackground)
    }
}
