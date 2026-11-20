import AppKit
import Carbon.HIToolbox
import CoreGraphics

/// Takes this Mac's own keyboard and mouse away from it while they are used
/// on another computer: a session event tap holds every key and mouse event
/// back and hands it to Dart, and the pointer stays frozen and hidden while
/// its moves still arrive as deltas. ⌃⌥⎋ is caught right here, so it brings
/// everything back even when Dart is busy.
final class InputCapture {
  static let escapeKey: Int64 = 0x35
  static let rightArrowKey: Int64 = 0x7C

  /// How long moves and scrolls add up before they go to Dart.
  private static let flushDelay: TimeInterval = 0.004

  var onEvents: (([NativeCapturedEvent]) -> Void)?
  var onSwitchKey: ((NativeSwitchKey) -> Void)?
  var onEnded: ((NativeCaptureEnd) -> Void)?

  private var tap: CFMachPort?
  private var source: CFRunLoopSource?
  private var secureInputTimer: Timer?
  private var cursorHidden = false
  private var queued: [NativeCapturedEvent] = []
  private var moveX = 0.0
  private var moveY = 0.0
  private var scrollX = 0.0
  private var scrollY = 0.0
  private var flushScheduled = false

  /// Switch keys held back on the way down, so their key up is too.
  private var swallowedKeys: Set<Int64> = []

  var isCapturing: Bool { tap != nil }

  static var access: NativeCaptureAccess {
    NativeCaptureAccess(
      inputMonitoring: CGPreflightListenEventAccess(), accessibility: AXIsProcessTrusted())
  }

  /// Shows each system prompt the first time; returns whether both are on.
  static func requestAccess() -> Bool {
    let listen = CGRequestListenEventAccess()
    let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let trusted = AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
    return listen && trusted
  }

  static var secureInputOn: Bool {
    IsSecureEventInputEnabled()
  }

  /// The modifier bits held now, or -1 when the tap couldn't be made.
  func start() -> Int64 {
    let held = Self.bits(of: CGEventSource.flagsState(.combinedSessionState))
    if tap != nil {
      return held
    }

    guard !Self.secureInputOn else { return -1 }

    let types: [CGEventType] = [
      .mouseMoved, .leftMouseDown, .leftMouseUp, .leftMouseDragged, .rightMouseDown,
      .rightMouseUp, .rightMouseDragged, .otherMouseDown, .otherMouseUp, .otherMouseDragged,
      .scrollWheel, .keyDown, .keyUp, .flagsChanged,
    ]
    let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
    let me = Unmanaged.passUnretained(self).toOpaque()
    guard
      let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
        eventsOfInterest: mask,
        callback: { _, type, event, userInfo in
          guard let userInfo else { return Unmanaged.passUnretained(event) }

          let capture = Unmanaged<InputCapture>.fromOpaque(userInfo).takeUnretainedValue()
          return capture.handle(type, event)
        }, userInfo: me)
    else {
      return -1
    }

    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    self.tap = tap
    self.source = source
    swallowedKeys.removeAll()
    queued.removeAll()
    (moveX, moveY, scrollX, scrollY) = (0, 0, 0, 0)

    CGAssociateMouseAndMouseCursorPosition(0)
    if CGDisplayHideCursor(CGMainDisplayID()) == .success {
      cursorHidden = true
    }

    secureInputTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
      [weak self] _ in
      guard Self.secureInputOn else { return }

      self?.end(.secureInput)
    }
    return held
  }

  /// Hands everything waiting to Dart, then gives the keyboard and mouse
  /// back.
  func stop() {
    guard let tap else { return }

    flush()
    CGEvent.tapEnable(tap: tap, enable: false)
    if let source {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
    }

    CFMachPortInvalidate(tap)
    self.tap = nil
    source = nil
    secureInputTimer?.invalidate()
    secureInputTimer = nil
    swallowedKeys.removeAll()
    CGAssociateMouseAndMouseCursorPosition(1)
    if cursorHidden {
      CGDisplayShowCursor(CGMainDisplayID())
      cursorHidden = false
    }
  }

  func end(_ reason: NativeCaptureEnd) {
    guard isCapturing else { return }

    stop()
    onEnded?(reason)
  }

  private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
    switch type {
    case .tapDisabledByTimeout, .tapDisabledByUserInput:
      reenable()
      return Unmanaged.passUnretained(event)
    case .keyDown, .keyUp:
      return key(event, pressed: type == .keyDown)
    case .flagsChanged:
      queue(.modifiers, modifiers: Self.bits(of: event.flags))
    case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
      moveX += event.getDoubleValueField(.mouseEventDeltaX)
      moveY += event.getDoubleValueField(.mouseEventDeltaY)
    case .leftMouseDown, .leftMouseUp:
      queue(.button, code: 0, pressed: type == .leftMouseDown)
    case .rightMouseDown, .rightMouseUp:
      queue(.button, code: 1, pressed: type == .rightMouseDown)
    case .otherMouseDown, .otherMouseUp:
      guard event.getIntegerValueField(.mouseEventButtonNumber) == 2 else { return nil }

      queue(.button, code: 2, pressed: type == .otherMouseDown)
    case .scrollWheel:
      scrollX += event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
      scrollY += event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
    default:
      return Unmanaged.passUnretained(event)
    }

    scheduleFlush()
    return nil
  }

  /// ⌃⌥⎋ and ⌃⌥→ act here and never reach the other computer.
  private func key(_ event: CGEvent, pressed: Bool) -> Unmanaged<CGEvent>? {
    let code = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags
    let isSwitch =
      flags.contains(.maskControl) && flags.contains(.maskAlternate)
      && !flags.contains(.maskCommand)
    if pressed, isSwitch, code == Self.escapeKey {
      swallowedKeys.insert(code)
      DispatchQueue.main.async { [weak self] in self?.end(.homeKey) }
      return nil
    }

    if pressed, isSwitch, code == Self.rightArrowKey {
      swallowedKeys.insert(code)
      flush()
      DispatchQueue.main.async { [weak self] in self?.onSwitchKey?(.next) }
      return nil
    }

    if swallowedKeys.contains(code) {
      if !pressed {
        swallowedKeys.remove(code)
      }

      return nil
    }

    var length = 0
    var characters = [UniChar](repeating: 0, count: 8)
    event.keyboardGetUnicodeString(
      maxStringLength: characters.count, actualStringLength: &length,
      unicodeString: &characters)
    queue(
      .key, code: code, pressed: pressed, modifiers: Self.bits(of: flags),
      isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
      text: String(utf16CodeUnits: characters, count: length))
    scheduleFlush()
    return nil
  }

  /// macOS turns a tap off when it was slow; take it back, or give up and
  /// hand the keyboard and mouse back.
  private func reenable() {
    guard let tap else { return }

    CGEvent.tapEnable(tap: tap, enable: true)
    guard !CGEvent.tapIsEnabled(tap: tap) else { return }

    DispatchQueue.main.async { [weak self] in self?.end(.tapFailed) }
  }

  private func queue(
    _ kind: NativeCaptureKind, code: Int64 = 0, pressed: Bool = false, modifiers: Int64 = 0,
    isRepeat: Bool = false, text: String? = nil
  ) {
    takeMotion()
    queued.append(
      NativeCapturedEvent(
        kind: kind, x: 0, y: 0, code: code, pressed: pressed, modifiers: modifiers,
        isRepeat: isRepeat, text: text))
  }

  /// Moves and scrolls that added up go before what comes next.
  private func takeMotion() {
    if moveX != 0 || moveY != 0 {
      queued.append(
        NativeCapturedEvent(
          kind: .move, x: moveX, y: moveY, code: 0, pressed: false, modifiers: 0,
          isRepeat: false))
      (moveX, moveY) = (0, 0)
    }

    if scrollX != 0 || scrollY != 0 {
      queued.append(
        NativeCapturedEvent(
          kind: .scroll, x: scrollX, y: scrollY, code: 0, pressed: false, modifiers: 0,
          isRepeat: false))
      (scrollX, scrollY) = (0, 0)
    }
  }

  private func scheduleFlush() {
    guard !flushScheduled else { return }

    flushScheduled = true
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.flushDelay) { [weak self] in
      self?.flush()
    }
  }

  private func flush() {
    flushScheduled = false
    takeMotion()
    guard !queued.isEmpty else { return }

    let events = queued
    queued.removeAll()
    onEvents?(events)
  }

  /// Bits: 1 shift, 2 control, 4 Option, 8 Command, as in `NativeInputEvent`.
  private static func bits(of flags: CGEventFlags) -> Int64 {
    var bits: Int64 = 0
    if flags.contains(.maskShift) {
      bits |= 1
    }

    if flags.contains(.maskControl) {
      bits |= 2
    }

    if flags.contains(.maskAlternate) {
      bits |= 4
    }

    if flags.contains(.maskCommand) {
      bits |= 8
    }

    return bits
  }
}
