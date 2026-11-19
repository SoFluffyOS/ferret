import SwiftUI

/// Where the share stands, as the picker shows it.
enum SharePhase: Equatable {
  case choosing

  /// A device was tapped; Ferret is being opened.
  case opening

  /// The request is left, but iOS didn't open Ferret from here.
  case openFerret

  case problem(String)
}

/// The picker's state, which the view controller drives.
final class ShareModel: ObservableObject {
  @Published var title = String(localized: "Send with Ferret")
  @Published var devices: [ShareDevice] = []
  @Published var phase: SharePhase = .choosing

  /// True while a tap waits for big files to finish copying.
  @Published var isWaiting = false
}

/// The device list in the share sheet: one tap sends.
struct SharePickerView: View {
  @ObservedObject var model: ShareModel
  let onPick: (ShareChoice) -> Void
  let onCancel: () -> Void
  let onDone: () -> Void

  var body: some View {
    NavigationView {
      content
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            if model.phase == .choosing {
              Button("Cancel", action: onCancel)
            }
          }
        }
    }
    .navigationViewStyle(.stack)
  }

  @ViewBuilder
  private var content: some View {
    switch model.phase {
    case .problem(let message):
      notice(message, symbol: "exclamationmark.triangle")
    case .openFerret:
      notice(
        String(localized: "Ready to send. Open Ferret and it sends right away."),
        symbol: "arrow.up.forward.app")
    case .opening:
      busy(String(localized: "Opening Ferret…"))
    case .choosing:
      if model.isWaiting {
        busy(String(localized: "Getting your files ready…"))
      } else if model.devices.isEmpty {
        noDevices
      } else {
        deviceList
      }
    }
  }

  private var deviceList: some View {
    List {
      Section(footer: Text("Ferret opens and sends while you watch.")) {
        ForEach(model.devices) { device in
          row(symbol: symbol(for: device.kind), label: device.name) {
            onPick(.device(device.id))
          }
        }
        if model.devices.count > 1 {
          row(symbol: "square.grid.2x2", label: String(localized: "All my devices")) {
            onPick(.everyDevice)
          }
        }
      }
    }
    .listStyle(.insetGrouped)
  }

  private var noDevices: some View {
    VStack(spacing: 16) {
      Image(systemName: "wifi.exclamationmark")
        .font(.largeTitle)
        .foregroundColor(.secondary)
      Text("No device connected")
        .font(.headline)
      Text("Open Ferret to connect to your devices. It sends as soon as it finds one.")
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      Button("Open Ferret") { onPick(.askInFerret) }
        .buttonStyle(.borderedProminent)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func notice(_ text: String, symbol: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: symbol)
        .font(.largeTitle)
        .foregroundColor(.secondary)
      Text(text)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      Button("Done", action: onDone)
        .buttonStyle(.borderedProminent)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func busy(_ text: String) -> some View {
    VStack(spacing: 12) {
      ProgressView()
      Text(text).foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func row(symbol: String, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Image(systemName: symbol)
          .frame(width: 28)
          .foregroundColor(.accentColor)
        Text(label)
          .foregroundColor(.primary)
          .lineLimit(1)
        Spacer()
      }
      .contentShape(Rectangle())
    }
    .accessibilityLabel("Send to \(label)")
  }

  private func symbol(for kind: String) -> String {
    switch kind {
    case "phone":
      return "iphone"
    case "tablet":
      return "ipad"
    case "desktop":
      return "desktopcomputer"
    default:
      return "laptopcomputer"
    }
  }
}
