import CoreAudio

/// The default output device's volume and mute, through Core Audio.
enum SystemVolume {
  /// `kAudioHardwareServiceDeviceProperty_VirtualMainVolume` ('vmvc'): the
  /// one volume the menu bar slider shows, across all channels.
  private static let virtualMainVolume = AudioObjectPropertySelector(0x766D_7663)
  private static let mainElement = AudioObjectPropertyElement(0)

  static var isSettable: Bool {
    guard let device = defaultOutputDevice() else {
      return false
    }

    var address = outputAddress(virtualMainVolume)
    var settable = DarwinBoolean(false)
    guard AudioObjectHasProperty(device, &address),
      AudioObjectIsPropertySettable(device, &address, &settable) == noErr
    else {
      return false
    }

    return settable.boolValue
  }

  /// 0 to 1, or nil when the device has no volume.
  static func volume() -> Float32? {
    guard let device = defaultOutputDevice() else {
      return nil
    }

    var address = outputAddress(virtualMainVolume)
    guard AudioObjectHasProperty(device, &address) else {
      return nil
    }

    var volume = Float32(0)
    var size = UInt32(MemoryLayout<Float32>.size)
    guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume) == noErr else {
      return nil
    }

    return volume
  }

  static func setVolume(_ volume: Float32) {
    guard let device = defaultOutputDevice() else {
      return
    }

    var address = outputAddress(virtualMainVolume)
    guard AudioObjectHasProperty(device, &address) else {
      return
    }

    var clamped = min(max(volume, 0), 1)
    let size = UInt32(MemoryLayout<Float32>.size)
    AudioObjectSetPropertyData(device, &address, 0, nil, size, &clamped)
  }

  static func isMuted() -> Bool {
    guard let device = defaultOutputDevice() else {
      return false
    }

    var address = outputAddress(kAudioDevicePropertyMute)
    guard AudioObjectHasProperty(device, &address) else {
      return false
    }

    var muted = UInt32(0)
    var size = UInt32(MemoryLayout<UInt32>.size)
    guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &muted) == noErr else {
      return false
    }

    return muted != 0
  }

  static func setMuted(_ muted: Bool) {
    guard let device = defaultOutputDevice() else {
      return
    }

    var address = outputAddress(kAudioDevicePropertyMute)
    guard AudioObjectHasProperty(device, &address) else {
      return
    }

    var value = UInt32(muted ? 1 : 0)
    let size = UInt32(MemoryLayout<UInt32>.size)
    AudioObjectSetPropertyData(device, &address, 0, nil, size, &value)
  }

  private static func defaultOutputDevice() -> AudioDeviceID? {
    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyDefaultOutputDevice,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: mainElement)
    var device = AudioDeviceID(kAudioObjectUnknown)
    var size = UInt32(MemoryLayout<AudioDeviceID>.size)
    let status = AudioObjectGetPropertyData(
      AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
    guard status == noErr, device != kAudioObjectUnknown else {
      return nil
    }

    return device
  }

  private static func outputAddress(_ selector: AudioObjectPropertySelector)
    -> AudioObjectPropertyAddress
  {
    AudioObjectPropertyAddress(
      mSelector: selector,
      mScope: kAudioDevicePropertyScopeOutput,
      mElement: mainElement)
  }
}
