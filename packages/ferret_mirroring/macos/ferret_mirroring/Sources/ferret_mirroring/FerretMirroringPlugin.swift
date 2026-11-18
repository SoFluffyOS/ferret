import Cocoa
import CoreVideo
import FlutterMacOS

/// Shows a mirrored phone screen: H.264 decoded with VideoToolbox into a
/// Flutter texture, and full screen for the window Flutter is in.
public class FerretMirroringPlugin: NSObject, FlutterPlugin, MirrorDecoderHostApi {
  private let registrar: FlutterPluginRegistrar
  private let flutterApi: MirrorDecoderFlutterApi
  private var texture: MirrorTexture?
  private var textureId: Int64?
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
    let texture = MirrorTexture()
    let textures = registrar.textures
    let id = textures.register(texture)
    let api = flutterApi
    self.texture = texture
    textureId = id
    decoder = H264Decoder(
      onPicture: { pixelBuffer, ptsUs in
        texture.show(pixelBuffer)
        let width = Int64(CVPixelBufferGetWidth(pixelBuffer))
        let height = Int64(CVPixelBufferGetHeight(pixelBuffer))
        Task { @MainActor in
          textures.textureFrameAvailable(id)
          try? await api.onDecoded(ptsUs: ptsUs, width: width, height: height)
        }
      },
      onError: { status in
        Task { @MainActor in
          try? await api.onDecodeError(status: Int64(status))
        }
      })
    return id
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
    texture = nil
    if let textureId {
      registrar.textures.unregisterTexture(textureId)
    }

    textureId = nil
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
