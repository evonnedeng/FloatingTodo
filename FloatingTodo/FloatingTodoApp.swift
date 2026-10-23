import SwiftUI
import AppKit

@main
struct FloatingTodoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        panel = FloatingPanel()

        let rootView = FloatingRootView { [weak self] expanded in
            self?.panel.setExpanded(expanded)
        }

        panel.contentView = NSHostingView(rootView: rootView)

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            panel.setFrameOrigin(
                NSPoint(
                    x: visible.maxX - 70,
                    y: visible.maxY - 70
                )
            )
        }

        panel.orderFrontRegardless()
    }
}

final class FloatingPanel: NSPanel {

    private let collapsedSize = NSSize(width: 60, height: 60)
    private let expandedSize = NSSize(width: 400, height: 520)

    init() {
        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: collapsedSize.width,
                height: collapsedSize.height
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        level = .floating

        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        isMovableByWindowBackground = true
        hidesOnDeactivate = false

        acceptsMouseMovedEvents = true
    }

    func setExpanded(_ expanded: Bool) {

        let oldFrame = frame
        let newSize = expanded ? expandedSize : collapsedSize

        // Keep top-right corner anchored
        let newFrame = NSRect(
            x: oldFrame.maxX - newSize.width,
            y: oldFrame.maxY - newSize.height,
            width: newSize.width,
            height: newSize.height
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(
                name: .easeInEaseOut
            )

            animator().setFrame(
                newFrame,
                display: true
            )
        }
    }
}
