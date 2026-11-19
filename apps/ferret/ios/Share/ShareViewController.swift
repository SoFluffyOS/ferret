import SwiftUI
import UIKit

/// The share sheet → Ferret: shows the devices Ferret last listed, leaves
/// what was shared for the app, then opens Ferret, which sends it while it
/// is on screen. Nothing is sent from here.
class ShareViewController: UIViewController {
  private static let wakeLink = "ferret://send"

  private let handoff = ShareHandoff()
  private let model = ShareModel()
  private var content = SharedContent()
  private var isReady = false
  private var pending: ShareChoice?
  private var isLeft = false

  override func viewDidLoad() {
    super.viewDidLoad()

    model.devices = handoff.devices()
    let picker = UIHostingController(
      rootView: SharePickerView(
        model: model,
        onPick: { [weak self] choice in self?.pick(choice) },
        onCancel: { [weak self] in self?.cancel() },
        onDone: { [weak self] in self?.finish() }
      ))
    addChild(picker)
    picker.view.frame = view.bounds
    picker.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(picker.view)
    picker.didMove(toParent: self)

    guard handoff.isReachable else {
      model.phase = .problem(
        String(localized: "Ferret can't reach its shared folder. Open Ferret once, then share again."))
      return
    }

    let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
    SharedContent.load(from: items, handoff: handoff) { [weak self] content in
      self?.loaded(content)
    }
  }

  private func loaded(_ content: SharedContent) {
    self.content = content
    isReady = true
    model.title = title(for: content)
    if content.isEmpty {
      model.isWaiting = false
      model.phase = .problem(String(localized: "Ferret couldn't read what you shared."))
      return
    }

    if let choice = pending {
      send(to: choice)
    }
  }

  /// A device tapped while big files are still being copied is remembered
  /// and sent to as soon as they are ready.
  private func pick(_ choice: ShareChoice) {
    guard isReady else {
      pending = choice
      model.isWaiting = true
      return
    }

    send(to: choice)
  }

  private func send(to choice: ShareChoice) {
    guard !content.isEmpty, !isLeft else {
      return
    }

    model.isWaiting = false
    guard handoff.leave(content, for: choice, devices: model.devices) else {
      model.phase = .problem(String(localized: "Ferret couldn't keep what you shared. Try again."))
      return
    }

    isLeft = true
    model.phase = .opening
    openFerret { [weak self] opened in
      guard opened else {
        self?.model.phase = .openFerret
        return
      }

      self?.finish()
    }
  }

  /// A share extension has no API to open its app. Apps do it by finding
  /// the application object up the responder chain and asking it to open a
  /// link; its method is closed to extensions at compile time, so it is
  /// called through the runtime. When that stops working, the request is
  /// still left and the picker says to open Ferret.
  private func openFerret(completion: @escaping (Bool) -> Void) {
    typealias OpenLink = @convention(c) (
      AnyObject, Selector, NSURL, NSDictionary, AnyObject?
    ) -> Void

    let selector = NSSelectorFromString("openURL:options:completionHandler:")
    guard let link = NSURL(string: ShareViewController.wakeLink) else {
      completion(false)
      return
    }

    var responder: UIResponder? = self
    while let current = responder {
      if current is UIApplication, current.responds(to: selector),
        let method = current.method(for: selector)
      {
        let done: @convention(block) (Bool) -> Void = { opened in
          DispatchQueue.main.async {
            completion(opened)
          }
        }
        let open = unsafeBitCast(method, to: OpenLink.self)
        open(current, selector, link, NSDictionary(), unsafeBitCast(done, to: AnyObject.self))
        return
      }

      responder = current.next
    }

    completion(false)
  }

  private func cancel() {
    handoff.discard(content)
    extensionContext?.cancelRequest(
      withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
  }

  /// Copies of a share that never got left for Ferret are of no use.
  private func finish() {
    if !isLeft {
      handoff.discard(content)
    }

    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }

  private func title(for content: SharedContent) -> String {
    if content.paths.isEmpty {
      if content.isLink {
        return String(localized: "Send link to…")
      }

      return String(localized: "Send text to…")
    }

    if content.names.count == 1, let name = content.names.first {
      return String(localized: "Send \(name) to…")
    }

    return String(localized: "Send \(content.paths.count) files to…")
  }
}
