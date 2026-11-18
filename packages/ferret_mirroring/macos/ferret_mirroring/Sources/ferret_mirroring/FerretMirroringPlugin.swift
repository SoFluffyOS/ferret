import Cocoa
import CoreVideo
import FlutterMacOS
import sofluffy_texture

/// Shows a mirrored phone screen: H.264 decoded with VideoToolbox into a
/// Flutter texture, and full screen for the window Flutter is in.
public class FerretMirroringPlugin: NSObject, FlutterPlugin, MirrorDecoderHostApi {
  private let registrar: FlutterPluginRegistrar
  private let flutterApi: MirrorDecoderFlutterApi
  private var texture: OpaquePointer?
  private var decoder: H264Decoder?

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    flutterApi = MirrorDecoderFlutterApi(binaryMessenger: registrar.messenger)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretMirroringPlugin(registrar: registrar)
    MirrorDecoderHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func create() throws -> Int64 {
    try dispose()
    guard let texture = sft_texture_create(registrar.textures, nil, nil) else {
      throw PigeonError(code: "no_texture", message: "Flutter refused the texture", details: nil)
    }

    let api = flutterApi
    self.texture = texture
    decoder = H264Decoder(
      texture: texture,
      onPicture: { width, height, ptsUs in
        Task { @MainActor in
          try? await api.onDecoded(ptsUs: ptsUs, width: Int64(width), height: Int64(height))
        }
      },
      onError: { status in
        Task { @MainActor in
          try? await api.onDecodeError(status: Int64(status))
        }
      })
    return sft_texture_id(texture)
  }

  func configure(sps: FlutterStandardTypedData, pps: FlutterStandardTypedData) throws {
    guard let decoder else {
      throw PigeonError(code: "no_decoder", message: "Call create first", details: nil)
    }

    let status = decoder.configure(sps: sps.data, pps: pps.data)
    guard status == noErr else {
      throw PigeonError(
        code: "bad_config", message: "VideoToolbox refused the stream (\(status))", details: nil)
    }
  }

  func decode(data: FlutterStandardTypedData, ptsUs: Int64, keyframe: Bool) throws {
    decoder?.decode(data: data.data, ptsUs: ptsUs, keyframe: keyframe)
  }

  func dispose() throws {
    decoder?.invalidate()
    decoder = nil
    sft_texture_dispose(texture)
    texture = nil
  }

  func canFullScreen() throws -> Bool {
    guard let window = registrar.view?.window else {
      return false
    }

    // The menubar popover is a window too, but one that can't go full screen.
    return window.styleMask.contains(.resizable) && window.styleMask.contains(.titled)
  }

  func isFullScreen() throws -> Bool {
    registrar.view?.window?.styleMask.contains(.fullScreen) ?? false
  }

  func setFullScreen(fullScreen: Bool) throws {
    guard try canFullScreen(), let window = registrar.view?.window else {
      return
    }

    if window.styleMask.contains(.fullScreen) == fullScreen {
      return
    }

    window.collectionBehavior.insert(.fullScreenPrimary)
    window.toggleFullScreen(nil)
  }
}
