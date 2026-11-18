import Foundation
import UniformTypeIdentifiers

/// What was shared, once read out of the share sheet's item providers.
struct SharedContent {
  /// Where Ferret should read each file: a copy it can reach, when one
  /// could be made.
  var paths: [String] = []

  /// The files where they were shared from. Fewer than [paths] when
  /// something arrived as data, with no file of its own.
  var originals: [String] = []
  var names: [String] = []

  /// The folder the copies are in, when there are any.
  var copyFolder: URL?
  var text: String?

  var isEmpty: Bool {
    return paths.isEmpty && (text ?? "").isEmpty
  }

  /// Reads every shared item, copying files where Ferret can reach them.
  /// Calls back on the main queue.
  static func load(
    from items: [NSExtensionItem], handoff: ShareHandoff,
    completion: @escaping (SharedContent) -> Void
  ) {
    let providers = items.flatMap { $0.attachments ?? [] }
    let folder = handoff.makeCopyFolder()
    let group = DispatchGroup()
    let lock = NSLock()
    var content = SharedContent()
    content.copyFolder = folder

    func add(file: URL, isLasting: Bool) {
      let path = handoff.copy(file, into: folder)
      lock.lock()
      content.paths.append(path)
      content.names.append(file.lastPathComponent)
      if isLasting {
        content.originals.append(file.path)
      }
      lock.unlock()
    }

    func add(text: String) {
      lock.lock()
      content.text = [content.text, text].compactMap { $0 }.joined(separator: "\n")
      lock.unlock()
    }

    for provider in providers {
      group.enter()
      if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
          if let file = fileURL(from: item) {
            add(file: file, isLasting: true)
          }
          group.leave()
        }
        continue
      }

      if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
          if let link = fileURL(from: item) {
            add(text: link.absoluteString)
          }
          group.leave()
        }
        continue
      }

      if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
          item, _ in
          if let text = item as? String {
            add(text: text)
          }
          group.leave()
        }
        continue
      }

      // A photo or a movie handed over as data, as Photos does: the system
      // writes it to a file that only lives until this block returns, so it
      // can only be sent as a copy.
      provider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { file, _ in
        if let file = file, folder != nil {
          add(file: file, isLasting: false)
        }
        group.leave()
      }
    }

    group.notify(queue: .main) {
      completion(content)
    }
  }

  /// Item providers hand a URL over as a URL, or as its bytes.
  private static func fileURL(from item: NSSecureCoding?) -> URL? {
    if let url = item as? URL {
      return url
    }

    if let data = item as? Data {
      return URL(dataRepresentation: data, relativeTo: nil)
    }

    return nil
  }
}
