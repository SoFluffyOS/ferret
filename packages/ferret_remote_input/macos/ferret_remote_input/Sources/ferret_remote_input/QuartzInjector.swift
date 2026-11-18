import AppKit
import CoreGraphics

/// Posts mouse and keyboard events as if they came from this Mac's own
/// devices. Tracks what it holds down, so it can let everything go when
/// control ends.
final class QuartzInjector {
  /// macOS caps a Unicode string on one key event at 20 UTF-16 units.
  private static let maxUnitsPerEvent = 20
  private static let returnKey: CGKeyCode = 0x24
  private static let tabKey: CGKeyCode = 0x30

  private let source: CGEventSource?
  private var heldButtons: Set<Int> = []
  private var heldKeys: [CGKeyCode: CGEventFlags] = [:]
  private var lastClick: (button: Int, time: TimeInterval, location: CGPoint, count: Int)?

  static var hasAccess: Bool {
    CGPreflightPostEventAccess()
  }

  /// Shows the system prompt the first time; returns whether access is on.
  static func requestAccess() -> Bool {
    CGRequestPostEventAccess()
  }

  init() {
    source = CGEventSource(stateID: .hidSystemState)
    // By default macOS ignores the real mouse and keyboard for a moment
    // after each posted event; the person at the Mac must keep control.
    source?.localEventsSuppressionInterval = 0
  }

  func inject(_ events: [NativeInputEvent]) {
    for event in events {
      switch event.kind {
      case .move:
        move(dx: CGFloat(event.x), dy: CGFloat(event.y))
      case .button:
        button(Int(event.code), pressed: event.pressed)
      case .scroll:
        scroll(dx: Int32(clamping: event.x), dy: Int32(clamping: event.y))
      case .key:
        key(
          CGKeyCode(clamping: event.code), pressed: event.pressed,
          flags: Self.flags(of: event.modifiers))
      case .mediaKey:
        mediaKey(Int(event.code), pressed: event.pressed)
      case .text:
        type(event.text ?? "")
      }
    }
  }

  func releaseAll() {
    for button in heldButtons {
      self.button(button, pressed: false)
    }

    for (code, flags) in heldKeys {
      key(code, pressed: false, flags: flags)
    }

    heldButtons.removeAll()
    heldKeys.removeAll()
  }

  private var location: CGPoint {
    CGEvent(source: nil)?.location ?? .zero
  }

  private func move(dx: CGFloat, dy: CGFloat) {
    let from = location
    let to = Self.clamp(CGPoint(x: from.x + dx, y: from.y + dy), near: from)
    let (type, button) = dragType()
    guard
      let event = CGEvent(
        mouseEventSource: source, mouseType: type, mouseCursorPosition: to,
        mouseButton: button)
    else {
      return
    }

    event.setIntegerValueField(.mouseEventDeltaX, value: Int64(dx))
    event.setIntegerValueField(.mouseEventDeltaY, value: Int64(dy))
    event.post(tap: .cghidEventTap)
  }

  /// A move while a button is down is a drag, or apps don't see it.
  private func dragType() -> (CGEventType, CGMouseButton) {
    if heldButtons.contains(0) {
      return (.leftMouseDragged, .left)
    }

    if heldButtons.contains(1) {
      return (.rightMouseDragged, .right)
    }

    if heldButtons.contains(2) {
      return (.otherMouseDragged, .center)
    }

    return (.mouseMoved, .left)
  }

  private func button(_ button: Int, pressed: Bool) {
    let types: (CGEventType, CGEventType, CGMouseButton)
    switch button {
    case 1:
      types = (.rightMouseDown, .rightMouseUp, .right)
    case 2:
      types = (.otherMouseDown, .otherMouseUp, .center)
    default:
      types = (.leftMouseDown, .leftMouseUp, .left)
    }

    let (downType, upType, mouseButton) = types
    let here = location
    let count = pressed ? clickCount(button: button, at: here) : (lastClick?.count ?? 1)
    guard
      let event = CGEvent(
        mouseEventSource: source, mouseType: pressed ? downType : upType,
        mouseCursorPosition: here, mouseButton: mouseButton)
    else {
      return
    }

    event.setIntegerValueField(.mouseEventClickState, value: Int64(count))
    event.post(tap: .cghidEventTap)
    if pressed {
      heldButtons.insert(button)
      return
    }

    heldButtons.remove(button)
  }

  /// Two clicks close in time and place are a double click, as on a real
  /// mouse; apps read it from the click state, not from timing.
  private func clickCount(button: Int, at point: CGPoint) -> Int {
    let now = ProcessInfo.processInfo.systemUptime
    var count = 1
    if let last = lastClick, last.button == button,
      now - last.time < NSEvent.doubleClickInterval,
      abs(last.location.x - point.x) < 4, abs(last.location.y - point.y) < 4
    {
      count = min(last.count + 1, 3)
    }

    lastClick = (button: button, time: now, location: point, count: count)
    return count
  }

  private func scroll(dx: Int32, dy: Int32) {
    guard
      let event = CGEvent(
        scrollWheelEvent2Source: source, units: .pixel, wheelCount: 2, wheel1: -dy,
        wheel2: -dx, wheel3: 0)
    else {
      return
    }

    event.post(tap: .cghidEventTap)
  }

  private func key(_ code: CGKeyCode, pressed: Bool, flags: CGEventFlags) {
    guard let event = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: pressed)
    else {
      return
    }

    event.flags = flags
    event.post(tap: .cghidEventTap)
    if pressed {
      heldKeys[code] = flags
      return
    }

    heldKeys.removeValue(forKey: code)
  }

  /// Media and volume keys are system-defined events, the way the Mac's own
  /// keyboard sends them.
  private func mediaKey(_ type: Int, pressed: Bool) {
    let state = pressed ? 0xa : 0xb
    let event = NSEvent.otherEvent(
      with: .systemDefined, location: .zero,
      modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(state << 8)), timestamp: 0,
      windowNumber: 0, context: nil, subtype: 8, data1: (type << 16) | (state << 8),
      data2: -1)
    event?.cgEvent?.post(tap: .cghidEventTap)
  }

  /// Types text whatever the keyboard layout, in chunks that never split a
  /// character. Line breaks and tabs are real key presses, so apps act on
  /// them.
  private func type(_ text: String) {
    var chunk: [UInt16] = []
    for character in text {
      if character == "\n" || character == "\r\n" || character == "\t" {
        postUnicode(chunk)
        chunk.removeAll()
        let code = character == "\t" ? Self.tabKey : Self.returnKey
        key(code, pressed: true, flags: [])
        key(code, pressed: false, flags: [])
        continue
      }

      let units = Array(String(character).utf16)
      if chunk.count + units.count > Self.maxUnitsPerEvent {
        postUnicode(chunk)
        chunk.removeAll()
      }

      chunk.append(contentsOf: units)
    }

    postUnicode(chunk)
  }

  private func postUnicode(_ units: [UInt16]) {
    guard !units.isEmpty else {
      return
    }

    for pressed in [true, false] {
      guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: pressed)
      else {
        continue
      }

      var buffer = units
      event.flags = []
      event.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: &buffer)
      event.post(tap: .cghidEventTap)
    }
  }

  private static func flags(of modifiers: Int64) -> CGEventFlags {
    var flags: CGEventFlags = []
    if modifiers & 1 != 0 {
      flags.insert(.maskShift)
    }

    if modifiers & 2 != 0 {
      flags.insert(.maskControl)
    }

    if modifiers & 4 != 0 {
      flags.insert(.maskAlternate)
    }

    if modifiers & 8 != 0 {
      flags.insert(.maskCommand)
    }

    return flags
  }

  /// Keeps the pointer on a screen: inside the display it would land on,
  /// else inside the one it came from.
  private static func clamp(_ point: CGPoint, near from: CGPoint) -> CGPoint {
    let displays = activeDisplayBounds()
    if displays.contains(where: { $0.contains(point) }) {
      return point
    }

    guard let home = displays.first(where: { $0.contains(from) }) ?? displays.first else {
      return point
    }

    return CGPoint(
      x: min(max(point.x, home.minX), home.maxX - 1),
      y: min(max(point.y, home.minY), home.maxY - 1))
  }

  private static func activeDisplayBounds() -> [CGRect] {
    var count: UInt32 = 0
    guard CGGetActiveDisplayList(0, nil, &count) == .success, count > 0 else {
      return []
    }

    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    guard CGGetActiveDisplayList(count, &displays, &count) == .success else {
      return []
    }

    return displays.prefix(Int(count)).map { CGDisplayBounds($0) }
  }
}
