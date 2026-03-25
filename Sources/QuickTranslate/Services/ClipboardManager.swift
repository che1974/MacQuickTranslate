import AppKit
import Carbon.HIToolbox

class ClipboardManager {
    /// Captures currently selected text by simulating Cmd+C, then restores the previous clipboard.
    func getSelectedText() async -> String? {
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)
        let previousChangeCount = pasteboard.changeCount

        simulateCopy()

        // Wait for clipboard to update
        try? await Task.sleep(nanoseconds: 200_000_000)

        guard pasteboard.changeCount != previousChangeCount,
              let text = pasteboard.string(forType: .string),
              !text.isEmpty else {
            return nil
        }

        // Restore previous clipboard content
        pasteboard.clearContents()
        if let prev = previousContent {
            pasteboard.setString(prev, forType: .string)
        }

        return text
    }

    private func simulateCopy() {
        let src = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: src,
                              virtualKey: UInt16(kVK_ANSI_C),
                              keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: src,
                            virtualKey: UInt16(kVK_ANSI_C),
                            keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
