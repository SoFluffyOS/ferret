import 'package:engine/engine.dart';
import 'package:feature_kit/feature_ui/activity_item.dart';
import 'package:feature_kit/feature_ui/device_permission.dart';
import 'package:feature_kit/feature_ui/feature_busy.dart';
import 'package:feature_kit/feature_ui/feature_context.dart';
import 'package:feature_kit/feature_ui/feature_health.dart';
import 'package:feature_kit/feature_ui/feature_nearby_row.dart';
import 'package:feature_kit/feature_ui/feature_offer.dart';
import 'package:feature_kit/feature_ui/feature_section.dart';
import 'package:feature_kit/feature_ui/feature_settings.dart';
import 'package:feature_kit/feature_ui/files_send_progress.dart';
import 'package:feature_kit/feature_ui/settings_group.dart';
import 'package:feature_kit/services/services.dart';
import 'package:flutter/widgets.dart';

/// The app side of a feature. The shell shows each feature's pieces in fixed
/// places, so features never touch the shell's code.
abstract class FeatureUi {
  /// Same id as the engine [Feature].
  String get featureId;

  /// The engine side, registered with the engine at startup.
  Feature get feature;

  /// The feature's own strings, added to the app's localizations.
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [];

  /// The notice action sets this feature uses, registered at startup.
  List<NoticeCategory> get noticeCategories => const [];

  /// Called once after the engine started, such as to ask for a permission
  /// or start a platform listener.
  Future<void> onAppStarted(FeatureContext context) async {}

  /// The feature's name as people see it, such as "Clipboard".
  String title(BuildContext context);

  IconData get icon;

  /// How this feature is doing with [device], or null when it can't apply to
  /// that device at all. The device's page lists every answer: working, off
  /// (say where to turn it on) or broken (offer a fix). Report real health
  /// (the last round trip), never just "connected".
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) => null;

  /// Fires when this feature's home card or health may have changed, so the
  /// shell rebuilds them right away.
  Listenable? get uiChanges => null;

  /// What this feature is in the middle of right now: a transfer under
  /// way, requests waiting for the person. Null when it never has any.
  /// The shell asks again whenever [uiChanges] fires.
  FeatureBusy? busyState(FeatureContext feature) => null;

  /// Whether the home card has anything to show right now. The shell leaves
  /// no gap for a feature that says no.
  ///
  /// A card is for the moments this feature needs the person: a request to
  /// answer, access that was lost. What merely happened belongs in
  /// [activity], and what can be done with a device in [deviceActions].
  bool hasHomeCard(FeatureContext feature) => true;

  /// What setting this feature up would give the user, or null when it is
  /// already on or can't be on here. Offers replace setup-only home cards:
  /// return false from [hasHomeCard] while you make an offer.
  FeatureOffer? offerFor(BuildContext context, FeatureContext feature) => null;

  /// A card on the home screen (the menubar popover on macOS), or null.
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) => null;

  /// What this feature did lately and what it is doing right now, for Home's
  /// Activity list: the visible trace of things that otherwise just happen,
  /// such as a clip that synced or a file that arrived. Any order; the shell
  /// sorts by [ActivityItem.at] and asks again whenever [uiChanges] fires.
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) =>
      const [];

  /// Actions for one connected device, such as "Send files", or empty. The
  /// ones with a [FeatureAction.homeOrder] sit on the device's row on Home;
  /// all of them are on the device's page.
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) => const [];

  /// What can still be done with [device] while it is offline, such as
  /// "Wake". They sit on its row on Home and on its page, next to the way
  /// to find out why it isn't connected.
  List<FeatureAction> offlineActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) => const [];

  /// What this feature is doing with an offline [device] right now, such
  /// as "Waking MacBook Pro…", shown in place of "Last seen". Null keeps
  /// the usual line.
  String? offlineStatus(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) => null;

  /// A group of its own on [device]'s page, under the action buttons, with
  /// its `SectionTitle`: for a set of things to do there that belong
  /// together, such as what a computer can do to itself ("This Mac":
  /// Sleep, Restart, Shut down). Null for none, which is the rule: a single
  /// action belongs in [deviceActions].
  Widget? buildDeviceGroup(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) => null;

  /// What this feature offers apart from any one device, such as "Recent
  /// clips…". The shell lists them in the ••• menu and the File menu.
  List<FeatureAction> appActions(
    BuildContext context,
    FeatureContext feature,
  ) => const [];

  /// The pages this feature has for [device], such as its texts, or empty.
  /// The device list shows them under the device in a window; on a phone
  /// they are pushed. Leave out a device the feature can never work with.
  /// Open one with [FeatureContext.openSection], never by pushing its page.
  List<FeatureSection> deviceSections(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) => const [];

  /// What is near this device that isn't paired and that this feature can
  /// still act on, such as a phone on a cable. The shell lists them under
  /// Nearby and asks again whenever [uiChanges] fires.
  List<FeatureNearbyRow> nearbyRows(
    BuildContext context,
    FeatureContext feature,
  ) => const [];

  /// The feature's section in Settings, or null.
  Widget? buildSettings(BuildContext context, FeatureContext feature) => null;

  /// The Settings row [buildSettings] sits behind.
  SettingsGroup get settingsGroup => .control;

  /// This feature's parts of Settings, each behind the row of its group.
  /// Override when the feature has parts in several groups, or to give the
  /// row its state ([FeatureSettings.summary], [FeatureSettings.isOn]).
  /// Leave out a part that can't apply on this device.
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final section = buildSettings(context, feature);
    if (section == null) {
      return const [];
    }

    return [
      FeatureSettings(
        group: settingsGroup,
        title: title(context),
        child: section,
      ),
    ];
  }

  /// What [device] may do on this one, as switches on its page: the
  /// per-device choices, such as controlling this computer without asking.
  /// App-wide defaults stay in Settings.
  List<DevicePermission> devicePermissions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) => const [];

  /// Files dropped on the app or on the menubar icon. Dropped on one
  /// device, [deviceId] names it and they go only there; otherwise they go
  /// to every connected device. Return null to leave them to another
  /// feature, or how sending them goes, ending with sent or failed.
  Future<Stream<FilesSendProgress>?> onFilesDropped(
    FeatureContext feature,
    List<String> paths, {
    String? deviceId,
  }) async => null;

  /// Text dragged onto the app, such as words selected on a web page. Like
  /// [onFilesDropped]: [deviceId] names the device it was dropped on, or
  /// null for every connected device; return null to leave it to another
  /// feature, or how sending it goes.
  Future<Stream<FilesSendProgress>?> onTextDropped(
    FeatureContext feature,
    String text, {
    String? deviceId,
  }) async => null;

  /// A web link dragged onto the app, such as from a browser's address
  /// bar, to open on [deviceId] (or every connected device when null).
  /// Return null to leave it to another feature.
  Future<Stream<FilesSendProgress>?> onLinkDropped(
    FeatureContext feature,
    Uri link, {
    String? deviceId,
  }) async => null;
}

/// Something a person can do with a feature, shown as a button.
class FeatureAction {
  const FeatureAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.id,
    this.homeOrder,
    this.sectionId,
  });

  /// Stays the same across languages and launches, prefixed with the
  /// feature id, such as `clipboard.send`. The shell counts uses by it to
  /// move a device's favourite action first, and finds well-known ones by
  /// it, such as the clipboard's for ⌘V on a device row. Null opts out.
  final String? id;

  /// A verb and its object, such as "Send files".
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Where this sits among the up to three actions on the device's row on
  /// Home, lowest first: Send files is 10, Send clipboard 20, Ring 30. Null
  /// keeps it on the device's page only.
  final int? homeOrder;

  /// The `FeatureSection.id` this only opens, such as `messages`, or null
  /// when it does something. Where the device list already shows that
  /// section, the shell leaves the button out.
  final String? sectionId;
}
