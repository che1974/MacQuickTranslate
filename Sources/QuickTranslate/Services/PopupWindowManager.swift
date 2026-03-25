import AppKit
import SwiftUI

@MainActor
class PopupWindowManager {
    private var panel: NSPanel?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?

    var isVisible: Bool { panel != nil }

    func show(translationService: TranslationService, sourceLanguage: Language, targetLanguage: Language) {
        dismiss()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        // Vibrancy background
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true

        let contentView = TranslationPopupView(
            translationService: translationService,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            onDismiss: { [weak self] in self?.dismiss() },
            onCopy: { [weak self] in self?.copyResult(translationService.translatedText) },
            onReplace: { [weak self] in self?.replaceText(translationService.translatedText) }
        )

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])

        panel.contentView = visualEffect

        positionNearCursor(panel)

        // Fade-in animation
        panel.alphaValue = 0
        panel.orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }

        self.panel = panel
        installEventMonitors()
    }

    func dismiss() {
        removeEventMonitors()
        guard let panel else {
            self.panel = nil
            return
        }
        // Fade-out animation
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
        self.panel = nil
    }

    private func installEventMonitors() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.dismiss()
                return nil
            }
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let panel = self.panel else { return }
            if !panel.frame.contains(NSEvent.mouseLocation) {
                self.dismiss()
            }
        }
    }

    private func removeEventMonitors() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
    }

    private func positionNearCursor(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let offset: CGFloat = 10
        var origin = NSPoint(
            x: mouseLocation.x + offset,
            y: mouseLocation.y - panel.frame.height - offset
        )

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            origin.x = min(origin.x, screenFrame.maxX - panel.frame.width)
            origin.y = max(origin.y, screenFrame.minY)
        }

        panel.setFrameOrigin(origin)
    }

    private func copyResult(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Copy translation to clipboard, dismiss popup, then simulate ⌘V to paste into the source app
    private func replaceText(_ text: String) {
        copyResult(text)
        dismiss()

        // Small delay to let the popup dismiss and focus return to the source app
        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            let src = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)  // 'v' key
            let keyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }
}
