import Foundation
import UIKit
import UniformTypeIdentifiers

/// What was shared, once read out of the share sheet's item providers.
struct SharedContent {
  /// The copies Ferret will send, in the shared folder.
  var paths: [String] = []
  var names: [String] = []

  /// Links and text, in the order they came, without repeats.
  var texts: [String] = []

  /// The folder the copies are in.
  var copyFolder: URL?

  /// How many items couldn't be read or copied.
  var missed = 0

  var text: String? {
    if texts.isEmpty {
      return nil
    }

    return texts.joined(separator: "\n")
  }

  var isEmpty: Bool {
    return paths.isEmpty && texts.isEmpty
  }

  var isLink: Bool {
    guard paths.isEmpty, texts.count == 1, let only = texts.first else {
      return false
    }

    return URL(string: only)?.scheme != nil
  }

  /// Reads every shared item, copying files into the shared folder. Calls
  /// back on the main queue.
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

    func add(path: String?, name: String) {
      lock.lock()
      defer { lock.unlock() }
      guard let path = path else {
        content.missed += 1
        return
      }

      content.paths.append(path)
      content.names.append(name)
    }

    func add(text: String?) {
      lock.lock()
      defer { lock.unlock() }
      let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !trimmed.isEmpty else {
        content.missed += 1
        return
      }

      if !content.texts.contains(trimmed) {
        content.texts.append(trimmed)
      }
    }

    func copy(file: URL, from provider: NSItemProvider) {
      guard let folder = folder else {
        add(path: nil, name: "")
        return
      }

      let name = fileName(for: file, from: provider)
      add(path: handoff.copy(file, named: name, into: folder), name: name)
    }

    for provider in providers {
      group.enter()
      if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
          if let file = url(from: item), file.isFileURL {
            copy(file: file, from: provider)
          } else {
            add(path: nil, name: "")
          }
          group.leave()
        }
        continue
      }

      if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
          add(text: url(from: item)?.absoluteString)
          group.leave()
        }
        continue
      }

      if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
          item, _ in
          add(text: item as? String)
          group.leave()
        }
        continue
      }

      // A folder from Files: the system hands over a copy that only lives
      // until this block returns, so its whole tree is copied here and
      // Ferret sends it as a folder.
      if provider.hasItemConformingToTypeIdentifier(UTType.folder.identifier) {
        provider.loadFileRepresentation(forTypeIdentifier: UTType.folder.identifier) { file, _ in
          if let file = file {
            copy(file: file, from: provider)
          } else {
            add(path: nil, name: "")
          }
          group.leave()
        }
        continue
      }

      // A photo or a video, as Photos hands them over: the system writes a
      // file that only lives until this block returns, so it is copied here.
      let type = dataType(of: provider)
      provider.loadFileRepresentation(forTypeIdentifier: type) { file, _ in
        if let file = file {
          copy(file: file, from: provider)
          group.leave()
          return
        }

        loadImage(from: provider) { data in
          guard let data = data, let folder = folder else {
            add(path: nil, name: "")
            group.leave()
            return
          }

          let name = "\(provider.suggestedName ?? "Image").png"
          add(path: handoff.write(data, named: name, into: folder), name: name)
          group.leave()
        }
      }
    }

    group.notify(queue: .main) {
      completion(content)
    }
  }

  /// Some apps hand over only a picture in memory, with no file at all.
  private static func loadImage(
    from provider: NSItemProvider, completion: @escaping (Data?) -> Void
  ) {
    guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
      completion(nil)
      return
    }

    provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
      if let image = item as? UIImage {
        completion(image.pngData())
        return
      }

      completion(item as? Data)
    }
  }

  /// The most specific kind of data the provider has, so the copy keeps
  /// its real extension (HEIC, MOV…).
  private static func dataType(of provider: NSItemProvider) -> String {
    let found = provider.registeredTypeIdentifiers.first { identifier in
      UTType(identifier)?.conforms(to: .data) ?? false
    }

    return found ?? UTType.data.identifier
  }

  /// The name the sharing app suggests, with the file's own extension.
  private static func fileName(for file: URL, from provider: NSItemProvider) -> String {
    let ext = file.pathExtension
    guard let suggested = provider.suggestedName, !suggested.isEmpty else {
      return file.lastPathComponent
    }

    if ext.isEmpty || suggested.lowercased().hasSuffix(".\(ext.lowercased())") {
      return suggested
    }

    return "\(suggested).\(ext)"
  }

  /// Item providers hand a URL over as a URL, or as its bytes or text.
  private static func url(from item: NSSecureCoding?) -> URL? {
    if let url = item as? URL {
      return url
    }

    if let data = item as? Data {
      return URL(dataRepresentation: data, relativeTo: nil)
    }

    if let text = item as? String {
      return URL(string: text)
    }

    return nil
  }
}
