import 'package:engine/engine.dart';
import 'package:feature_kit/feature_ui/drag_out.dart';
import 'package:feature_kit/feature_ui/drop_receiver.dart';
import 'package:feature_kit/feature_ui/feature_window.dart';
import 'package:feature_kit/feature_ui/link_opener.dart';
import 'package:feature_kit/feature_ui/local_network_gate.dart';
import 'package:feature_kit/feature_ui/system_drags.dart';
import 'package:feature_kit/navigation/navigation.dart';
import 'package:feature_kit/services/services.dart';
import 'package:flutter/widgets.dart';

/// What the app hands a [FeatureUi]: the running engine, and a way to show
/// things in the app's navigator.
class FeatureContext {
  FeatureContext({
    required this.engine,
    required this.navigatorKey,
    required this.notifier,
    Future<void> Function()? onReveal,
    bool Function(String deviceId)? showsPreviewsFrom,
  }) : _onReveal = onReveal,
       _showsPreviewsFrom = showsPreviewsFrom;

  final FerretEngine engine;

  /// Shows system notifications on this device.
  final LocalNotifier notifier;
  final GlobalKey<NavigatorState> navigatorKey;

  final Future<void> Function()? _onReveal;
  final bool Function(String deviceId)? _showsPreviewsFrom;

  /// Whether private things from [deviceId], such as copied text, may show
  /// on this screen right now: false while it's locked, another account is
  /// in front, or the person hid that device's previews here.
  bool showsPreviewsFrom(String deviceId) =>
      _showsPreviewsFrom?.call(deviceId) ?? true;

  /// Ends Ferret the way its own Quit does: features stop and connected
  /// devices get a goodbye. Null until the shell set it.
  Future<void> Function()? quit;

  /// How [openSection] shows a section. The shell sets it once its views
  /// exist.
  Future<void> Function(String deviceId, String sectionId)? onOpenSection;

  /// Windows a feature can open for itself, such as one in the shape of a
  /// phone's screen. Null until the shell set it, and where it has none.
  FeatureWindows? windows;

  /// Drags out of Ferret into other apps. Null until the shell set it,
  /// and where the platform has none.
  DragOut? dragOut;

  /// Shows files in the system's quick preview (Quick Look on a Mac), or
  /// closes it when it is open. Null where there is none.
  Future<void> Function(List<String> paths)? quickLook;

  /// Drags going on in other apps, seen from outside. Null where the
  /// platform shows none.
  SystemDrags? systemDrags;

  /// A small panel over every app, such as the shelf while dragging. Null
  /// where the platform has none.
  FloatingPanel? floatingPanel;

  /// Says why Ferret needs the local network before iOS asks. Null where
  /// nothing asks, or once the shell has none to give.
  LocalNetworkGate? localNetwork;

  /// Lets Ferret on the local network, saying why first where that is
  /// still needed. True when it may go ahead.
  Future<bool> askLocalNetwork(BuildContext context) async =>
      await localNetwork?.ask(context) ?? true;

  /// Where things dropped on the menubar icon stay when they aren't sent,
  /// such as the shelf. Set by the feature that keeps them.
  DropReceiver? dropKeeper;

  /// Opens a shared link on another device. Set by the feature that
  /// continues links there; null where none does.
  LinkOpener? linkOpener;

  /// Brings Ferret to the front (the menubar popover on macOS), such as when
  /// this device starts ringing.
  Future<void> reveal() async {
    final onReveal = _onReveal;
    if (onReveal == null) {
      return;
    }

    await onReveal();
  }

  /// Opens [page] on top of the app, such as a file picker result or a
  /// conversation.
  Future<T?> push<T>(Widget page) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return null;
    }

    return navigator.push(ferretRoute<T>(page));
  }

  /// Shows a section of the device [deviceId] (a `FeatureSection.id`):
  /// pushed on a phone, selected next to the device list in a window.
  Future<void> openSection(String deviceId, String sectionId) async {
    final onOpenSection = this.onOpenSection;
    if (onOpenSection == null) {
      return;
    }

    await onOpenSection(deviceId, sectionId);
  }
}
