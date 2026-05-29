import SwiftUI

struct MainView: View {
    @StateObject private var model: ArchivePreviewModel
    let coordinator: ArchivePreviewCoordinator

    init(rootNode: ArchiveNode, archiveURL: URL, coordinator: ArchivePreviewCoordinator) {
        _model = StateObject(wrappedValue: ArchivePreviewModel(rootNode: rootNode, archiveURL: archiveURL))
        self.coordinator = coordinator
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

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
        .background(.windowBackground)
        .background(
            ArchiveKeyboardMonitor(
                onCopy: model.copySelectedItems,
                onNavigateUp: model.navigateUpIfPossible,
                onNavigateForward: model.navigateForwardIfPossible
            )
        )
        .onCopyCommand {
            model.copySelectedItems()
            return []
        }
        .onAppear {
            coordinator.previewModel = model
        }
        .onDisappear {
            coordinator.previewModel = nil
        }
        .onChange(of: model.selectedNodeIds) { _, _ in
            model.noteSelection()
        }
        .onChange(of: model.bannerMessage) { _, message in
            model.headerHeight = message != nil
                ? ArchivePreviewModel.navigationBarHeight + ArchivePreviewModel.bannerHeight
                : ArchivePreviewModel.navigationBarHeight
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var headerBar: some View {
        VStack(spacing: 0) {
            ArchiveNavigationBar(
                canGoUp: model.canGoUp,
                canGoForward: model.canGoForward,
                onGoUp: model.navigateUp,
                onGoForward: model.navigateForward
            )
            .archiveNavBarStyle()

            if let bannerMessage = model.bannerMessage {
                Text(bannerMessage)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.bar)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .zIndex(1)
    }
}
