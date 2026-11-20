import Carbon.HIToolbox
import Cocoa

/// One fixed key combination that reaches the app from anywhere on the Mac,
/// such as ⌃⌥→. Carbon's `RegisterEventHotKey`, like the menubar's own
/// shortcuts: it hears only its own combination and needs no permission.
/// Ids 1 and 2 belong to the menubar's shortcuts, so these start at 3.
final class SwitchHotKey {
  /// "FRRT", shared with the menubar's hot keys; the id tells them apart.
  private static let signature: OSType = 0x4652_5254

  private let id: UInt32
  private let keyCode: UInt32
  private let modifiers: UInt32
  private var hotKey: EventHotKeyRef?
  private var handler: EventHandlerRef?

  var onPressed: (() -> Void)?

  init(id: UInt32, keyCode: Int, modifiers: Int) {
    self.id = id
    self.keyCode = UInt32(keyCode)
    self.modifiers = UInt32(modifiers)
  }

  deinit {
    unregister()
    if let handler {
      RemoveEventHandler(handler)
    }
  }

  /// False when the Mac refused it, such as when another app holds it.
  func register() -> Bool {
    guard hotKey == nil else { return true }

    installHandler()
    let hotKeyId = EventHotKeyID(signature: Self.signature, id: id)
    let status = RegisterEventHotKey(
      keyCode, modifiers, hotKeyId, GetApplicationEventTarget(), 0, &hotKey)
    guard status == noErr else {
      hotKey = nil
      return false
    }

    return true
  }

  func unregister() {
    guard let hotKey else { return }

    UnregisterEventHotKey(hotKey)
    self.hotKey = nil
  }

  private func installHandler() {
    guard handler == nil else { return }

    var pressed = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let me = Unmanaged.passUnretained(self).toOpaque()
    InstallEventHandler(
      GetApplicationEventTarget(),
      { _, event, userData in
        guard let userData, let event else { return OSStatus(eventNotHandledErr) }

        var pressedId = EventHotKeyID()
        GetEventParameter(
          event, EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID), nil,
          MemoryLayout<EventHotKeyID>.size, nil, &pressedId)
        let hotKey = Unmanaged<SwitchHotKey>.fromOpaque(userData).takeUnretainedValue()
        guard pressedId.signature == SwitchHotKey.signature, pressedId.id == hotKey.id else {
          return OSStatus(eventNotHandledErr)
        }

        DispatchQueue.main.async { hotKey.onPressed?() }
        return noErr
      }, 1, &pressed, me, &handler)
  }
}
