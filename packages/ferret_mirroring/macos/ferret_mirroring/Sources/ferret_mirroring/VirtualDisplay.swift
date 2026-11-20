// An extra display that only exists in software, made with CoreGraphics'
// private CGVirtualDisplay classes.
//
// Based on OpenDisplay (https://github.com/peetzweg/opendisplay, GPL-3.0):
// Mac/VirtualDisplay.swift and Mac/CGVirtualDisplayPrivate.h, the display
// setup, the HiDPI mode it selects and keeps, and taking it out of a mirror
// set. The interface itself was first published by Khaos Tian
// (VirtualDisplayExp) and is also used by DeskPad and BetterDisplay.
//
// Ferret looks the classes up at run time instead of linking them through a
// header: a macOS that drops them makes `VirtualDisplay.isAvailable` false
// instead of stopping the whole app from launching.
//
// The private interface, as used here:
//
//   @interface CGVirtualDisplayDescriptor : NSObject
//   @property(retain) NSString *name;
//   @property unsigned int maxPixelsWide, maxPixelsHigh;
//   @property CGSize sizeInMillimeters;
//   @property unsigned int serialNum, productID, vendorID;
//   @property(copy) void (^terminationHandler)(id, CGVirtualDisplay *);
//   - (void)setDispatchQueue:(dispatch_queue_t)queue;
//   @end
//
//   @interface CGVirtualDisplayMode : NSObject
//   - (instancetype)initWithWidth:(NSUInteger)width height:(NSUInteger)height
//                     refreshRate:(CGFloat)refreshRate;
//   @end
//
//   @interface CGVirtualDisplaySettings : NSObject
//   @property(retain) NSArray<CGVirtualDisplayMode *> *modes;
//   @property unsigned int hiDPI;
//   @end
//
//   @interface CGVirtualDisplay : NSObject
//   @property(readonly) CGDirectDisplayID displayID;
//   - (instancetype)initWithDescriptor:(CGVirtualDisplayDescriptor *)descriptor;
//   - (BOOL)applySettings:(CGVirtualDisplaySettings *)settings;
//   @end

import AppKit
import CoreGraphics
import Foundation

/// Makes macOS believe one more monitor is plugged in, sized in points at
/// `scale` (2 is HiDPI: a 2560×1600 pixel viewer gets 1280×800 points). The
/// display goes away when this object is released.
final class VirtualDisplay {
  private typealias ModeInit =
    @convention(c) (AnyObject, Selector, UInt, UInt, CGFloat) -> Unmanaged<AnyObject>?
  private typealias ApplySettings = @convention(c) (AnyObject, Selector, AnyObject) -> ObjCBool

  private static let descriptorClass = NSClassFromString("CGVirtualDisplayDescriptor") as? NSObject.Type
  private static let settingsClass = NSClassFromString("CGVirtualDisplaySettings") as? NSObject.Type
  private static let modeClass: AnyClass? = NSClassFromString("CGVirtualDisplayMode")
  private static let displayClass: AnyClass? = NSClassFromString("CGVirtualDisplay")
  private static let modeInit = NSSelectorFromString("initWithWidth:height:refreshRate:")
  private static let displayInit = NSSelectorFromString("initWithDescriptor:")
  private static let apply = NSSelectorFromString("applySettings:")
  private static let setQueue = NSSelectorFromString("setDispatchQueue:")
  private static let alloc = NSSelectorFromString("alloc")

  /// The private classes are there, with the methods Ferret calls.
  static var isAvailable: Bool {
    guard let descriptorClass, let settingsClass, let modeClass, let displayClass else {
      return false
    }

    return descriptorClass.instancesRespond(to: setQueue)
      && settingsClass.instancesRespond(to: NSSelectorFromString("setModes:"))
      && class_respondsToSelector(modeClass, modeInit)
      && class_respondsToSelector(displayClass, displayInit)
      && class_respondsToSelector(displayClass, apply)
  }

  private let display: NSObject
  private var enforcement: Timer?
  private var settled = false
  private var refusals = 0

  let pointsWide: Int
  let pointsHigh: Int
  let scale: Int
  let refreshHz: Int

  var displayID: CGDirectDisplayID {
    (display.value(forKey: "displayID") as? NSNumber)?.uint32Value ?? 0
  }

  var pixelsWide: Int { pointsWide * scale }
  var pixelsHigh: Int { pointsHigh * scale }

  /// Must be called on the main thread. `serial` should be the same for the
  /// same viewer every time: macOS keeps a display's place in the
  /// arrangement by its vendor, product and serial.
  init?(
    name: String, pixelsWide: Int, pixelsHigh: Int, scale: Int, refreshHz: Int, serial: UInt32,
    onTerminated: @escaping () -> Void
  ) {
    guard VirtualDisplay.isAvailable, let descriptorClass = Self.descriptorClass,
      let displayClass = Self.displayClass
    else {
      return nil
    }

    let scale = scale >= 2 ? 2 : 1
    // Modes are whole points, and HiDPI wants even pixels.
    let pointsWide = max(pixelsWide / scale, 320)
    let pointsHigh = max(pixelsHigh / scale, 240)
    self.pointsWide = pointsWide
    self.pointsHigh = pointsHigh
    self.scale = scale
    // The private display tops out at 60 Hz.
    self.refreshHz = min(max(refreshHz, 30), 60)

    let longest = max(pointsWide, pointsHigh) * scale
    let maxPixels = (longest + 1) & ~1
    // About the density of a Mac's own screen, so text comes out the same
    // size as there.
    let pixelsPerInch: Double = scale == 2 ? 220 : 110
    let millimeters = CGSize(
      width: Double(pointsWide * scale) / pixelsPerInch * 25.4,
      height: Double(pointsHigh * scale) / pixelsPerInch * 25.4)

    let descriptor = descriptorClass.init()
    _ = descriptor.perform(Self.setQueue, with: DispatchQueue.main)
    descriptor.setValue(name, forKey: "name")
    descriptor.setValue(NSNumber(value: UInt32(maxPixels)), forKey: "maxPixelsWide")
    descriptor.setValue(NSNumber(value: UInt32(maxPixels)), forKey: "maxPixelsHigh")
    descriptor.setValue(NSValue(size: millimeters), forKey: "sizeInMillimeters")
    descriptor.setValue(NSNumber(value: serial), forKey: "serialNum")
    // "FT" and "FR": Ferret's own, apart from any real monitor's.
    descriptor.setValue(NSNumber(value: UInt32(0x4654)), forKey: "productID")
    descriptor.setValue(NSNumber(value: UInt32(0x4652)), forKey: "vendorID")
    let terminated: @convention(block) (AnyObject?, AnyObject?) -> Void = { _, _ in
      onTerminated()
    }
    descriptor.setValue(unsafeBitCast(terminated, to: AnyObject.self), forKey: "terminationHandler")

    // alloc's +1 is taken over by init, which hands back its own +1.
    guard let allocated = (displayClass as AnyObject).perform(Self.alloc)?.takeUnretainedValue(),
      let made = allocated.perform(Self.displayInit, with: descriptor)?.takeRetainedValue()
        as? NSObject
    else {
      return nil
    }

    display = made
    guard apply(), displayID != 0 else {
      return nil
    }

    // macOS starts a new display at its 1x mode and may bring back a saved
    // mode for this serial seconds later, or put it in a mirror set: keep
    // the HiDPI mode and the extended desktop for as long as it lives.
    enforcement = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
      self?.enforce()
    }
  }

  deinit {
    enforcement?.invalidate()
  }

  private func apply() -> Bool {
    guard let settingsClass = Self.settingsClass, let modeClass = Self.modeClass,
      let modeImp = class_getMethodImplementation(modeClass, Self.modeInit),
      let applyImp = class_getMethodImplementation(type(of: display), Self.apply),
      let allocated = (modeClass as AnyObject).perform(Self.alloc)?.takeUnretainedValue()
    else {
      return false
    }

    let makeMode = unsafeBitCast(modeImp, to: ModeInit.self)
    guard
      let mode = makeMode(
        allocated, Self.modeInit, UInt(pointsWide), UInt(pointsHigh), CGFloat(refreshHz))?
        .takeRetainedValue()
    else {
      return false
    }

    let settings = settingsClass.init()
    settings.setValue([mode], forKey: "modes")
    settings.setValue(NSNumber(value: UInt32(scale == 2 ? 1 : 0)), forKey: "hiDPI")
    let applySettings = unsafeBitCast(applyImp, to: ApplySettings.self)
    return applySettings(display, Self.apply, settings).boolValue
  }

  private func enforce() {
    keepOutOfMirrorSet()
    if selectMode() && !settled {
      settled = true
      enforcement?.invalidate()
      enforcement = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
        self?.enforce()
      }
    }
  }

  /// True once the display runs the mode made for it, or there is nothing
  /// more to try.
  private func selectMode() -> Bool {
    let id = displayID
    let options = [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary
    guard let modes = CGDisplayCopyAllDisplayModes(id, options) as? [CGDisplayMode],
      let wanted = modes.first(where: {
        $0.width == pointsWide && $0.height == pointsHigh
          && $0.pixelWidth == pointsWide * scale && $0.pixelHeight == pointsHigh * scale
      })
    else {
      return false
    }

    if let current = CGDisplayCopyDisplayMode(id), current.width == wanted.width,
      current.height == wanted.height, current.pixelWidth == wanted.pixelWidth,
      current.pixelHeight == wanted.pixelHeight
    {
      refusals = 0
      return true
    }

    // Some small HiDPI modes are listed and then refused every time: stop
    // asking after a few, so the log and the display settle.
    if refusals >= 5 {
      return true
    }

    var config: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&config) == .success else {
      return false
    }

    CGConfigureDisplayWithDisplayMode(config, id, wanted, nil)
    let result = CGCompleteDisplayConfiguration(config, .permanently)
    if result != .success {
      refusals += 1
    }

    return result == .success
  }

  /// An extra display belongs next to the others, never mirroring one.
  /// Session scope: a permanent change of the private display's mirror set
  /// is refused, and this runs again whenever macOS brings the set back.
  private func keepOutOfMirrorSet() {
    let id = displayID
    guard CGDisplayIsInMirrorSet(id) == 1 else {
      return
    }

    var config: CGDisplayConfigRef?
    guard CGBeginDisplayConfiguration(&config) == .success else {
      return
    }

    CGConfigureDisplayMirrorOfDisplay(config, id, kCGNullDirectDisplay)
    var count: UInt32 = 0
    CGGetActiveDisplayList(0, nil, &count)
    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    CGGetActiveDisplayList(count, &displays, &count)
    for other in displays where other != id && CGDisplayMirrorsDisplay(other) == id {
      CGConfigureDisplayMirrorOfDisplay(config, other, kCGNullDirectDisplay)
    }

    CGCompleteDisplayConfiguration(config, .forSession)
  }
}
