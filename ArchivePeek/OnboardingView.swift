import AppKit
import SwiftUI

struct OnboardingView: View {
    var body: some View {
        HStack(spacing: 0) {
            SidebarSummary()

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set up ArchivePeek")
                            .font(.system(size: 28, weight: .semibold))

                        Text("Preview archive contents from Finder without uncompressing the whole file.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 10) {
                        SetupStepRow(
                            symbol: "switch.2",
                            title: "Enable the Quick Look extension",
                            detail: "Open System Settings, then turn on ArchivePeek under Quick Look extensions.",
                            actionTitle: "Open Settings",
                            action: openExtensionSettings
                        )

                        SetupStepRow(
                            symbol: "archivebox",
                            title: "Select an archive in Finder",
                            detail: "ZIP, RAR, 7z, TAR, TGZ, and GZ archives can be inspected from Quick Look.",
                            actionTitle: nil,
                            action: nil
                        )

                        SetupStepRow(
                            symbol: "space",
                            title: "Press Space",
                            detail: "Browse folders inside the archive, copy paths, and extract a selected item when needed.",
                            actionTitle: nil,
                            action: nil
                        )
                    }
                    .layoutPriority(1)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Supported formats")
                            .font(.headline)

                        HStack(spacing: 8) {
                            FormatPill("ZIP")
                            FormatPill("RAR")
                            FormatPill("7z")
                            FormatPill("TAR")
                            FormatPill("TGZ")
                            FormatPill("GZ")
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 24)

                    HStack(spacing: 12) {
                        Button(action: openDocumentation) {
                            Label("Documentation", systemImage: "book")
                        }

                        Spacer()

                        Button(action: openExtensionSettings) {
                            Label("Enable Extension", systemImage: "gearshape")
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    }
                    .controlSize(.large)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 34)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: 760, height: 520)
    }

    private func openExtensionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openDocumentation() {
        if let url = URL(string: "https://github.com/methsithchan/ArchivePeek") {
            NSWorkspace.shared.open(url)
        }
    }
}

private struct SidebarSummary: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            AppMark()

            VStack(alignment: .leading, spacing: 6) {
                Text("ArchivePeek")
                    .font(.system(size: 24, weight: .semibold))

                Text("Quick Look archive browser")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                SidebarDetail(symbol: "lock.shield", text: "Runs inside the macOS Quick Look sandbox")
                SidebarDetail(symbol: "folder", text: "Browse folders before extracting")
                SidebarDetail(symbol: "square.and.arrow.down", text: "Extract only the selected item")
            }

            Spacer()

            Text("Version 2.0")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 26)
        .padding(.top, 28)
        .padding(.bottom, 24)
        .frame(width: 250)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
    }
}

private struct AppMark: View {
    var body: some View {
        Image(nsImage: AppMark.icon)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: 64, height: 64)
            .shadow(color: .black.opacity(0.14), radius: 10, y: 5)
    }

    private static var icon: NSImage {
        if let appIcon = NSApplication.shared.applicationIconImage,
           appIcon.size.width > 0, appIcon.size.height > 0 {
            return appIcon
        }
        return NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
    }
}

private struct SidebarDetail: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct SetupStepRow: View {
    let symbol: String
    let title: String
    let detail: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct FormatPill: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.background.opacity(0.65), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.separator.opacity(0.4), lineWidth: 1)
            }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
