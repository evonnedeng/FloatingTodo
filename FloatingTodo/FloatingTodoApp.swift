import SwiftUI
import AppKit

@main
struct FloatingTodoApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}


// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    var panel: FloatingPanel!

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        NSApp.setActivationPolicy(.accessory)

        panel = FloatingPanel()

        let rootView = FloatingRootView { [weak self] expanded in
            self?.panel.setExpanded(expanded)
        }

        let hostingView = NSHostingView(
            rootView: rootView
        )

        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        panel.contentView = hostingView

        if let screen = NSScreen.main {

            let visible = screen.visibleFrame

            panel.setFrameOrigin(
                NSPoint(
                    x: visible.maxX - 55,
                    y: visible.maxY - 55
                )
            )
        }

        panel.orderFrontRegardless()
    }
}


// MARK: - Floating Panel

final class FloatingPanel: NSPanel {

    private let collapsedSize = NSSize(
        width: 40,
        height: 40
    )

    private let expandedSize = NSSize(
        width: 280,
        height: 370
    )

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    init() {

        super.init(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: collapsedSize.width,
                height: collapsedSize.height
            ),
            styleMask: [
                .borderless,
                .nonactivatingPanel
            ],
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


    // MARK: - Expand / Collapse

    func setExpanded(_ expanded: Bool) {

        let oldFrame = frame

        let newSize = expanded
            ? expandedSize
            : collapsedSize

        let newFrame = NSRect(
            x: oldFrame.maxX - newSize.width,
            y: oldFrame.maxY - newSize.height,
            width: newSize.width,
            height: newSize.height
        )

        NSAnimationContext.runAnimationGroup { context in

            context.duration = 0.25

            context.timingFunction =
                CAMediaTimingFunction(
                    name: .easeInEaseOut
                )

            animator().setFrame(
                newFrame,
                display: true
            )
        }

        if expanded {
            makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
