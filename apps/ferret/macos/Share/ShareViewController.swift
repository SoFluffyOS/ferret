import Cocoa
import SwiftUI

/// Finder's Share menu → Ferret: shows the connected devices, then leaves
/// the files for the Ferret app to send. Nothing is sent from here.
class ShareViewController: NSViewController {
  private let handoff = ShareHandoff()
  private var content = SharedContent()
  private var devices: [ShareDevice] = []
  private var isReady = false
  private var problem: String?
  private var pending: ShareChoice?
  private var isSending = false
  private var following: NSObjectProtocol?

  override func loadView() {
    devices = handoff.devices()
    view = NSHostingView(rootView: picker())
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    following = handoff.followDevices { [weak self] devices in
      self?.devices = devices
      self?.refresh()
    }

    let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
    SharedContent.load(from: items, handoff: handoff) { [weak self] content in
      self?.loaded(content)
    }
  }

  deinit {
    if let following = following {
      handoff.stopFollowing(following)
    }
  }

  private func loaded(_ content: SharedContent) {
    self.content = content
    isReady = true
    if content.isEmpty {
      problem = String(localized: "Ferret couldn't read what you shared.")
    }
    refresh()

    if let choice = pending {
      send(to: choice)
    }
  }

  /// A device clicked while big files are still being copied is remembered
  /// and sent to as soon as they are ready.
  private func pick(_ choice: ShareChoice) {
    guard isReady else {
      pending = choice
      refresh()
      return
    }

    send(to: choice)
  }

  private func send(to choice: ShareChoice) {
    guard !content.isEmpty, !isSending else {
      return
    }

    pending = choice
    isSending = true
    refresh()
    handoff.send(content, to: choice) { [weak self] taken in
      self?.sent(taken)
    }
  }

  private func sent(_ taken: Bool) {
    guard taken else {
      isSending = false
      pending = nil
      problem = String(localized: "Ferret couldn't take the files. Open Ferret and drag them onto its icon instead.")
      refresh()
      return
    }

    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }

  private func cancel() {
    extensionContext?.cancelRequest(
      withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
  }

  private func refresh() {
    (view as? NSHostingView<SharePickerView>)?.rootView = picker()
  }

  private func picker() -> SharePickerView {
    return SharePickerView(
      title: title(),
      devices: devices,
      isBusy: isSending || (pending != nil && !isReady),
      problem: problem,
      onPick: { [weak self] choice in self?.pick(choice) },
      onCancel: { [weak self] in self?.cancel() }
    )
  }

  private func title() -> String {
    guard isReady else {
      return String(localized: "Send with Ferret")
    }

    if content.paths.isEmpty {
      return String(localized: "Send text to…")
    }

    if content.names.count == 1, let name = content.names.first {
      return String(localized: "Send \(name) to…")
    }

    return String(localized: "Send \(content.paths.count) files to…")
  }
}
