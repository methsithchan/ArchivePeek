import AppKit

/// Native navigation bar hosted directly in the preview view controller, outside SwiftUI.
@MainActor
final class ArchiveAppKitNavBar: NSView {
    private let backButton: ImmediateButton
    private let forwardButton: ImmediateButton
    private weak var coordinator: ArchivePreviewCoordinator?

    override var isFlipped: Bool { true }

    init(coordinator: ArchivePreviewCoordinator) {
        self.coordinator = coordinator
        backButton = Self.makeButton(symbol: "chevron.left", tag: 0)
        forwardButton = Self.makeButton(symbol: "chevron.right", tag: 1)
        super.init(frame: .zero)

        let background = NSVisualEffectView()
        background.material = .headerView
        background.blendingMode = .withinWindow
        background.state = .followsWindowActiveState
        background.translatesAutoresizingMaskIntoConstraints = false
        addSubview(background)
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        backButton.target = self
        backButton.action = #selector(backTapped)
        backButton.onMouseDown = { [weak self] in self?.backTapped() }
        forwardButton.target = self
        forwardButton.action = #selector(forwardTapped)
        forwardButton.onMouseDown = { [weak self] in self?.forwardTapped() }

        let stack = NSStackView(views: [backButton, forwardButton])
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 28),
            forwardButton.widthAnchor.constraint(equalToConstant: 32),
            forwardButton.heightAnchor.constraint(equalToConstant: 28),
        ])

        updateState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func attach(coordinator: ArchivePreviewCoordinator) {
        self.coordinator = coordinator
        updateState()
    }

    func updateState() {
        backButton.isEnabled = coordinator?.previewModel?.canGoUp ?? false
        forwardButton.isEnabled = coordinator?.previewModel?.canGoForward ?? false
    }

    @objc private func backTapped() {
        coordinator?.previewModel?.navigateUp()
        updateState()
    }

    @objc private func forwardTapped() {
        coordinator?.previewModel?.navigateForward()
        updateState()
    }

    private static func makeButton(symbol: String, tag: Int) -> ImmediateButton {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        let button = ImmediateButton(image: image ?? NSImage(), target: nil, action: nil)
        button.tag = tag
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false
        button.toolTip = tag == 0 ? "Go to enclosing folder (←)" : "Forward (→)"
        return button
    }

    /// Fires on mouse-down so Quick Look never waits for double-click detection.
    private final class ImmediateButton: NSButton {
        var onMouseDown: (() -> Void)?

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            guard isEnabled else { return }
            onMouseDown?()
        }
    }
}

/// Root layout: AppKit nav bar on top, SwiftUI content below.
@MainActor
final class ArchivePreviewRootView: NSView {
    let navBar: ArchiveAppKitNavBar
    let contentView: NSView

    override var isFlipped: Bool { true }

    init(navBar: ArchiveAppKitNavBar, contentView: NSView) {
        self.navBar = navBar
        self.contentView = contentView
        super.init(frame: .zero)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        addSubview(navBar)
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: topAnchor),
            navBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: ArchivePreviewModel.navigationBarHeight),
            contentView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
