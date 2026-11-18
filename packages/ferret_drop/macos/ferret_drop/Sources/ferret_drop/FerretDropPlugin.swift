import Cocoa
import FlutterMacOS

/// Opens received files and shows them in Finder.
public class FerretDropPlugin: NSObject, FlutterPlugin, FerretDropHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FerretDropPlugin()
    FerretDropHostApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func takePendingShares() throws -> [SharedItems] {
    return []
  }

  func canSaveToDownloads() throws -> Bool {
    return false
  }

  func saveToDownloads(
    sourcePath: String, fileName: String, mimeType: String, folder: String
  ) async throws -> SavedFile {
    throw PigeonError(
      code: "unsupported", message: "Save the file in the receive folder instead", details: nil)
  }

  func open(location: String, mimeType: String) throws -> Bool {
    let url = URL(fileURLWithPath: location)
    guard FileManager.default.fileExists(atPath: url.path) else {
      return false
    }

    return NSWorkspace.shared.open(url)
  }

  func reveal(location: String) throws -> Bool {
    let url = URL(fileURLWithPath: location)
    guard FileManager.default.fileExists(atPath: url.path) else {
      return false
    }

    NSWorkspace.shared.activateFileViewerSelecting([url])
    return true
  }
}
