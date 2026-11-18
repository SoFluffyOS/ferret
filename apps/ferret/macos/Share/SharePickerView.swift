import SwiftUI

/// The device list in the Share menu: one click sends.
struct SharePickerView: View {
  let title: String
  let devices: [ShareDevice]
  let isBusy: Bool
  let problem: String?
  let onPick: (ShareChoice) -> Void
  let onCancel: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)
        .lineLimit(2)

      content

      HStack {
        Spacer()
        Button("Cancel", action: onCancel)
          .keyboardShortcut(.cancelAction)
      }
    }
    .padding(16)
    .frame(width: 320)
  }

  @ViewBuilder
  private var content: some View {
    if let problem = problem {
      Text(problem)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    } else if isBusy {
      HStack(spacing: 8) {
        ProgressView().controlSize(.small)
        Text("Handing over to Ferret…").foregroundColor(.secondary)
      }
    } else if devices.isEmpty {
      VStack(alignment: .leading, spacing: 8) {
        Text("No device is connected right now. Ferret can open and send as soon as it finds one.")
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        Button("Open Ferret") { onPick(.askInFerret) }
          .keyboardShortcut(.defaultAction)
      }
    } else {
      VStack(spacing: 4) {
        ForEach(devices) { device in
          ShareRow(symbol: symbol(for: device.kind), label: device.name) {
            onPick(.device(device.id))
          }
        }
        if devices.count > 1 {
          ShareRow(symbol: "circle.grid.2x2", label: "All my devices") {
            onPick(.everyDevice)
          }
        }
      }
    }
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

/// A full-width row that fills on hover, so a click never needs aim.
private struct ShareRow: View {
  let symbol: String
  let label: String
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: symbol)
          .frame(width: 22)
        Text(label)
          .lineLimit(1)
        Spacer()
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.accentColor.opacity(isHovered ? 0.16 : 0.06))
    )
    .onHover { isHovered = $0 }
  }
}
