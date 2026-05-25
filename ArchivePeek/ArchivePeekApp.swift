import SwiftUI

@main
struct ArchivePeekApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .frame(width: 760, height: 520)
                .onAppear {
                    // Prevent resizing the window beyond onboarding constraints
                    if let window = NSApplication.shared.windows.first {
                        window.styleMask.remove(.resizable)
                        window.setContentSize(NSSize(width: 760, height: 520))
                        window.titleVisibility = .hidden
                        window.titlebarAppearsTransparent = true
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
