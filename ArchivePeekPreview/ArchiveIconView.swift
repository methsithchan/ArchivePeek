import SwiftUI
import UniformTypeIdentifiers

struct ArchiveIconView: View {
    let nodes: [ArchiveNode]
    let selection: Set<UUID>
    let onSelect: (ArchiveNode, Bool) -> Void
    let onActivate: (ArchiveNode) -> Void
    let onOpen: (ArchiveNode) -> Void
    let onCopy: (ArchiveNode) -> Void
    let onExtract: (ArchiveNode) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 88, maximum: 120), spacing: 16)
    ]

    var body: some View {
        if nodes.isEmpty {
            ContentUnavailableView {
                Label {
                    Text("Empty Folder")
                } icon: {
                    ArchiveFileIcon(contentType: .folder, size: 48)
                }
            }
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 28) {
                    ForEach(nodes, id: \.id) { node in
                        iconItem(for: node)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func iconItem(for node: ArchiveNode) -> some View {
        let isSelected = selection.contains(node.id)

        return Button {
            onSelect(node, false)
        } label: {
            VStack(spacing: 6) {
                ArchiveFileIcon(node: node, size: 64)
                Text(node.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(isSelected ? Color.accentColor.opacity(0.15) : .clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                onSelect(node, false)
                onActivate(node)
            }
        )
        .contextMenu {
            if node.isDirectory {
                Button("Open") { onOpen(node) }
                Divider()
            }
            Button("Copy") { onCopy(node) }
            Button("Extract…") { onExtract(node) }
        }
    }
}
