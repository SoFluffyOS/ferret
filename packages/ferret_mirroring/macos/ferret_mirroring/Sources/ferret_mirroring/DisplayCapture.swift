// An extra display for another device: made, captured and encoded here,
// sent by the Dart side. The capture follows OpenDisplay
// (https://github.com/peetzweg/opendisplay, GPL-3.0), Mac/MacSender.swift:
// only that display, 420v straight into the encoder, and frames dropped
// before encoding while the pipeline is busy, so the H.264 chain stays whole.

import AppKit
import ApplicationServices
import CoreGraphics
import CoreMedia
import FlutterMacOS
import Foundation
import ScreenCaptureKit

final class DisplayCapture: NSObject, DisplayCaptureHostApi {
  private let flutterApi: DisplayCaptureFlutterApi
  private var display: VirtualDisplay?
  private var streamer: AnyObject?
  private var input: DisplayPointerInput?
  private var terminateObserver: NSObjectProtocol?

  init(binaryMessenger: FlutterBinaryMessenger) {
    flutterApi = DisplayCaptureFlutterApi(binaryMessenger: binaryMessenger)
    super.init()
    // The display never outlives Ferret.
    terminateObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification, object: nil, queue: .main
    ) { [weak self] _ in
      self?.tearDown()
    }
  }

  deinit {
    if let terminateObserver {
      NotificationCenter.default.removeObserver(terminateObserver)
    }
  }

  func support() throws -> NativeDisplaySupport {
    var canExtend = VirtualDisplay.isAvailable
    if #unavailable(macOS 12.3) {
      canExtend = false
    }

    return NativeDisplaySupport(
      canExtend: canExtend,
      screenRecordingGranted: CGPreflightScreenCaptureAccess(),
      inputGranted: AXIsProcessTrusted())
  }

  func requestScreenRecording() throws -> Bool {
    if CGPreflightScreenCaptureAccess() {
      return true
    }

    return CGRequestScreenCaptureAccess()
  }

  func requestInput() throws -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
  }

  func openScreenRecordingSettings() throws {
    let page = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    if let url = URL(string: page) {
      NSWorkspace.shared.open(url)
    }
  }

  func start(options: NativeDisplayOptions) async throws {
    guard #available(macOS 12.3, *) else {
      throw PigeonError(code: "unsupported", message: "Needs macOS 12.3", details: nil)
    }

    await MainActor.run { tearDown() }
    let made = await MainActor.run {
      VirtualDisplay(
        name: options.name,
        pixelsWide: Int(options.width),
        pixelsHigh: Int(options.height),
        scale: Int(options.scale),
        refreshHz: Int(options.refreshHz),
        serial: UInt32(truncatingIfNeeded: options.serial),
        onTerminated: { [weak self] in self?.ended(.endedBySystem) })
    }
    guard let made else {
      throw PigeonError(code: "no_display", message: "macOS refused the display", details: nil)
    }

    let streamer = DisplayStreamer(
      displayID: made.displayID,
      width: made.pixelsWide,
      height: made.pixelsHigh,
      fps: made.refreshHz,
      bitrate: Int(options.bitrate),
      flutterApi: flutterApi,
      onEnded: { [weak self] end in self?.ended(end) })
    await MainActor.run {
      display = made
      self.streamer = streamer
      input = DisplayPointerInput(displayID: made.displayID)
    }
    do {
      try await streamer.start()
    } catch {
      await MainActor.run { tearDown() }
      throw PigeonError(
        code: "no_capture", message: error.localizedDescription, details: nil)
    }
  }

  func stop() async throws {
    await MainActor.run { tearDown() }
  }

  func requestKeyframe() throws {
    if #available(macOS 12.3, *) {
      (streamer as? DisplayStreamer)?.requestKeyframe()
    }
  }

  func setBitrate(bitrate: Int64) throws {
    if #available(macOS 12.3, *) {
      (streamer as? DisplayStreamer)?.setBitrate(Int(bitrate))
    }
  }

  func pointer(event: NativeDisplayPointer) throws {
    input?.handle(event)
  }

  /// Stops capturing and takes the display away: windows on it move back
  /// to the Mac's own screens.
  private func tearDown() {
    if #available(macOS 12.3, *) {
      (streamer as? DisplayStreamer)?.stop()
    }

    input?.releaseAll()
    input = nil
    streamer = nil
    display = nil
  }

  private func ended(_ end: NativeCaptureEnd) {
    DispatchQueue.main.async { [weak self] in
      guard let self, self.display != nil else {
        return
      }

      self.tearDown()
      let api = self.flutterApi
      Task { @MainActor in
        try? await api.onEnded(end: end)
      }
    }
  }
}

@available(macOS 12.3, *)
private final class DisplayStreamer: NSObject, SCStreamOutput, SCStreamDelegate {
  /// Frames in the encoder or on their way to Dart at which new ones are
  /// dropped. Dart drops more when the network backs up.
  private static let maxInFlight = 3

  private let displayID: CGDirectDisplayID
  private let width: Int
  private let height: Int
  private let fps: Int
  private let flutterApi: DisplayCaptureFlutterApi
  private let onEnded: (NativeCaptureEnd) -> Void
  private let queue = DispatchQueue(label: "ferret.display.capture", qos: .userInteractive)
  private let lock = NSLock()
  private var encoder: DisplayEncoder?
  private var stream: SCStream?
  private var stopped = false
  private var inFlight = 0
  private var wantsKeyframe = true
  private var lastPixelBuffer: CVPixelBuffer?
  private var lastPts = CMTime.zero
  private var bitrate: Int

  init(
    displayID: CGDirectDisplayID, width: Int, height: Int, fps: Int, bitrate: Int,
    flutterApi: DisplayCaptureFlutterApi, onEnded: @escaping (NativeCaptureEnd) -> Void
  ) {
    self.displayID = displayID
    self.width = width
    self.height = height
    self.fps = fps
    self.bitrate = bitrate
    self.flutterApi = flutterApi
    self.onEnded = onEnded
  }

  func start() async throws {
    let encoder = try DisplayEncoder(width: width, height: height, fps: fps, bitrate: bitrate)
    let scDisplay = try await findDisplay()
    let configuration = SCStreamConfiguration()
    configuration.width = width
    configuration.height = height
    // Asking for exactly the display's rate makes ScreenCaptureKit skip
    // frames that arrive a hair early; twice as often gets every one.
    configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(fps * 2))
    configuration.pixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    configuration.queueDepth = 6
    configuration.showsCursor = true

    let filter = SCContentFilter(display: scDisplay, excludingWindows: [])
    let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
    try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
    lock.locked {
      self.encoder = encoder
      self.stream = stream
    }
    try await stream.startCapture()
  }

  func stop() {
    let (stream, encoder) = lock.locked { () -> (SCStream?, DisplayEncoder?) in
      stopped = true
      let taken = (self.stream, self.encoder)
      self.stream = nil
      self.encoder = nil
      lastPixelBuffer = nil
      return taken
    }
    stream?.stopCapture { _ in }
    encoder?.invalidate()
  }

  /// The next frame decodes on its own. On a screen where nothing moves
  /// no new frame comes, so the last one is sent again.
  func requestKeyframe() {
    queue.async { [weak self] in
      guard let self else {
        return
      }

      self.lock.locked { self.wantsKeyframe = true }
      if let last = self.lock.locked({ self.lastPixelBuffer }) {
        let pts = CMClockGetTime(CMClockGetHostTimeClock())
        self.encode(last, pts: pts)
      }
    }
  }

  func setBitrate(_ bitrate: Int) {
    lock.locked {
      self.bitrate = bitrate
      encoder?.setBitrate(bitrate)
    }
  }

  func stream(
    _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of type: SCStreamOutputType
  ) {
    guard type == .screen, CMSampleBufferIsValid(sampleBuffer), isComplete(sampleBuffer),
      let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else {
      return
    }

    lock.locked { lastPixelBuffer = pixelBuffer }
    encode(pixelBuffer, pts: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
  }

  func stream(_ stream: SCStream, didStopWithError error: Error) {
    let stopped = lock.locked { self.stopped }
    if stopped {
      return
    }

    let byUser = (error as? SCStreamError)?.code == .userStopped
    onEnded(byUser ? .stoppedByUser : .failed)
  }

  /// ScreenCaptureKit also sends frames that only say nothing changed.
  private func isComplete(_ sample: CMSampleBuffer) -> Bool {
    guard
      let attachments = CMSampleBufferGetSampleAttachmentsArray(sample, createIfNecessary: false)
        as? [[SCStreamFrameInfo: Any]],
      let raw = attachments.first?[.status] as? Int,
      let status = SCFrameStatus(rawValue: raw)
    else {
      return false
    }

    return status == .complete
  }

  /// On `queue`. A busy pipeline drops the frame before it is encoded,
  /// which the decoder never notices.
  private func encode(_ pixelBuffer: CVPixelBuffer, pts: CMTime) {
    let taken = lock.locked { () -> (DisplayEncoder, Bool)? in
      guard !stopped, let encoder, inFlight < Self.maxInFlight, pts > lastPts else {
        return nil
      }

      inFlight += 1
      lastPts = pts
      let keyframe = wantsKeyframe
      wantsKeyframe = false
      return (encoder, keyframe)
    }
    guard let (encoder, keyframe) = taken else {
      return
    }

    let accepted = encoder.encode(pixelBuffer, pts: pts, keyframe: keyframe) { [weak self] picture in
      self?.deliver(picture, keyframe: keyframe)
    }
    if !accepted {
      lock.locked {
        inFlight -= 1
        wantsKeyframe = wantsKeyframe || keyframe
      }
    }
  }

  private func deliver(_ picture: EncodedPicture?, keyframe: Bool) {
    guard let picture else {
      lock.locked {
        inFlight -= 1
        wantsKeyframe = wantsKeyframe || keyframe
      }
      return
    }

    let api = flutterApi
    let size = (width, height, fps)
    Task { @MainActor [weak self] in
      if let sets = picture.parameterSets {
        try? await api.onConfig(
          config: NativeStreamConfig(
            codec: .h264, width: Int64(size.0), height: Int64(size.1), rotation: 0,
            fps: Int64(size.2), sps: FlutterStandardTypedData(bytes: sets.sps),
            pps: FlutterStandardTypedData(bytes: sets.pps), turn: nil))
      }

      try? await api.onFrame(
        frame: NativeFrame(
          data: FlutterStandardTypedData(bytes: picture.data), ptsUs: picture.ptsUs,
          keyframe: picture.keyframe))
      guard let self else {
        return
      }

      self.lock.locked { self.inFlight -= 1 }
    }
  }

  private func findDisplay() async throws -> SCDisplay {
    // A new display takes a moment to show up among the ones that can be
    // captured.
    for _ in 0..<20 {
      let content = try await SCShareableContent.excludingDesktopWindows(
        false, onScreenWindowsOnly: true)
      if let found = content.displays.first(where: { $0.displayID == displayID }) {
        return found
      }

      try await Task.sleep(nanoseconds: 250_000_000)
    }

    throw PigeonError(
      code: "no_display", message: "The display never became capturable", details: nil)
  }
}

/// The viewer's pointer, placed on the extra display: hovering moves the
/// pointer, a press and release click, moving while pressed drags.
final class DisplayPointerInput {
  private let displayID: CGDirectDisplayID
  private let source = CGEventSource(stateID: .hidSystemState)
  private var held: CGMouseButton?
  private var lastDown: (at: TimeInterval, point: CGPoint, button: CGMouseButton)?
  private var clickCount = 1

  init(displayID: CGDirectDisplayID) {
    self.displayID = displayID
  }

  func handle(_ event: NativeDisplayPointer) {
    let point = place(x: event.x, y: event.y)
    switch event.phase {
    case .hover:
      post(.mouseMoved, at: point, button: .left)
    case .move:
      guard let held else {
        post(.mouseMoved, at: point, button: .left)
        return
      }

      post(Self.dragType(held), at: point, button: held)
    case .down:
      let button = Self.button(event.button)
      if let held {
        post(Self.upType(held), at: point, button: held)
      }

      held = button
      clickCount = countClick(at: point, button: button)
      post(Self.downType(button), at: point, button: button)
    case .up:
      let button = held ?? Self.button(event.button)
      held = nil
      post(Self.upType(button), at: point, button: button)
    case .scroll:
      scroll(at: point, dx: event.scrollX, dy: event.scrollY)
    }
  }

  /// Lets go of a button still held, so nothing stays pressed when the
  /// display goes away.
  func releaseAll() {
    guard let held else {
      return
    }

    let location = CGEvent(source: nil)?.location ?? .zero
    post(Self.upType(held), at: location, button: held)
    self.held = nil
  }

  private func place(x: Double, y: Double) -> CGPoint {
    let bounds = CGDisplayBounds(displayID)
    let clampedX = min(max(x, 0), 1)
    let clampedY = min(max(y, 0), 1)
    // The last pixel column and row still belong to this display.
    return CGPoint(
      x: bounds.origin.x + min(clampedX * bounds.width, bounds.width - 1),
      y: bounds.origin.y + min(clampedY * bounds.height, bounds.height - 1))
  }

  private func countClick(at point: CGPoint, button: CGMouseButton) -> Int {
    let now = ProcessInfo.processInfo.systemUptime
    defer { lastDown = (now, point, button) }
    guard let last = lastDown, last.button == button,
      now - last.at <= NSEvent.doubleClickInterval,
      hypot(point.x - last.point.x, point.y - last.point.y) <= 4
    else {
      return 1
    }

    return clickCount + 1
  }

  private func post(_ type: CGEventType, at point: CGPoint, button: CGMouseButton) {
    guard
      let event = CGEvent(
        mouseEventSource: source, mouseType: type, mouseCursorPosition: point, mouseButton: button)
    else {
      return
    }

    if type != .mouseMoved {
      event.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
    }

    if button == .center {
      event.setIntegerValueField(.mouseEventButtonNumber, value: 2)
    }

    event.post(tap: .cghidEventTap)
  }

  /// Positive is right and down, in points; the wheel's own sign is the
  /// other way.
  private func scroll(at point: CGPoint, dx: Double, dy: Double) {
    guard
      let event = CGEvent(
        scrollWheelEvent2Source: source, units: .pixel, wheelCount: 2,
        wheel1: Int32((-dy).rounded()), wheel2: Int32((-dx).rounded()), wheel3: 0)
    else {
      return
    }

    event.location = point
    event.post(tap: .cghidEventTap)
  }

  private static func button(_ index: Int64) -> CGMouseButton {
    switch index {
    case 1: return .right
    case 2: return .center
    default: return .left
    }
  }

  private static func downType(_ button: CGMouseButton) -> CGEventType {
    switch button {
    case .right: return .rightMouseDown
    case .center: return .otherMouseDown
    default: return .leftMouseDown
    }
  }

  private static func upType(_ button: CGMouseButton) -> CGEventType {
    switch button {
    case .right: return .rightMouseUp
    case .center: return .otherMouseUp
    default: return .leftMouseUp
    }
  }

  private static func dragType(_ button: CGMouseButton) -> CGEventType {
    switch button {
    case .right: return .rightMouseDragged
    case .center: return .otherMouseDragged
    default: return .leftMouseDragged
    }
  }
}

extension NSLock {
  fileprivate func locked<T>(_ body: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try body()
  }
}
