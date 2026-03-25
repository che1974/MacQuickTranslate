import AppKit
import HotKey

class HotkeyManager {
    private var hotKey: HotKey?
    var onHotkey: (() -> Void)?

    func register() {
        hotKey = HotKey(key: .t, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.onHotkey?()
        }
    }

    func unregister() {
        hotKey = nil
    }
}
