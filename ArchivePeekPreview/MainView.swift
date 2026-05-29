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
            if let bannerMessage = model.bannerMessage {
                Text(bannerMessage)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.bar)
            }
            ArchiveFolderPane(model: model)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.windowBackground)
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
        .onChange(of: model.bannerMessage) { _, message in
            model.headerHeight = message != nil ? ArchivePreviewModel.bannerHeight : 0
        }
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}
