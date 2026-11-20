import 'dart:async';
import 'dart:io';

import 'package:clipboard/feature/clipboard_feature.dart';
import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/ui/clip_activity.dart';
import 'package:clipboard/ui/clip_send_report.dart';
import 'package:clipboard/ui/clipboard_health.dart';
import 'package:clipboard/ui/frames/frames.dart';
import 'package:clipboard/ui/pages/pages.dart';
import 'package:clipboard/ui/widgets/widgets.dart';
import 'package:clipboard/view_models/clipboard_view_model.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of Clipboard: what synced in Activity, "Send clipboard" for
/// each device, the Settings section, and Send clipboard from the Android
/// tile and notification or the Windows and Linux tray.
class ClipboardFeatureUi extends FeatureUi {
  ClipboardFeatureUi({ClipboardFeature? feature, this.recentClipsKeys})
    : feature = feature ?? ClipboardFeature();

  /// The keys that open Recent clips from any app, such as "⌃⌥V", or null
  /// when there are none here. The app knows them; this module doesn't.
  final String? Function(FeatureContext feature)? recentClipsKeys;

  static const _resultNoticeId = 'clipboard.result';

  @override
  final ClipboardFeature feature;

  late final ClipboardViewModel viewModel = ClipboardViewModel(feature);
  StreamSubscription<Object?>? _systemActions;

  @override
  String get featureId => ClipboardFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    ClipboardLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.clipboardL10n.title;

  @override
  IconData get icon => LucideIcons.clipboard;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    final hasSystemActions =
        Platform.isAndroid || Platform.isWindows || Platform.isLinux;
    if (!hasSystemActions) {
      return;
    }

    _systemActions = FerretSystem().actions
        .where((action) => action.id == SystemAction.clipboardSend)
        .listen(
          (action) => unawaited(_sendFromSystem(context, action.data['text'])),
        );
  }

  @override
  Listenable get uiChanges => viewModel;

  /// A power-up already lets this phone send in the background; only the
  /// switch is left.
  @override
  FeatureOffer? offerFor(BuildContext context, FeatureContext feature) {
    if (!viewModel.offersBackgroundSend) {
      return null;
    }

    final l10n = context.clipboardL10n;
    return FeatureOffer(
      title: l10n.title,
      description: l10n.offerBackgroundSend,
      actionLabel: l10n.offerTurnOn,
      onAction: () => unawaited(viewModel.setBackgroundSend(true)),
    );
  }

  /// Clipboard just works, so it has no card: what synced shows in
  /// Activity, and Send clipboard sits on each device.
  @override
  bool hasHomeCard(FeatureContext feature) => false;

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) =>
      clipActivity(context.clipboardL10n, viewModel);

  @override
  List<FeatureAction> deviceActions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final session = device.session;
    if (session == null || !session.supports(featureId)) {
      return const [];
    }

    return [
      FeatureAction(
        id: 'clipboard.send',
        label: context.clipboardL10n.sendClipboard,
        icon: LucideIcons.clipboardCopy,
        homeOrder: 20,
        onPressed: () => unawaited(_sendTo(context, device)),
      ),
    ];
  }

  Future<void> _sendTo(BuildContext context, DeviceStatus device) async {
    final result = await viewModel.sendClipboard(toDeviceId: device.device.id);
    if (result == null || !context.mounted) {
      return;
    }

    reportClipSend(context, result, device.device.name);
  }

  @override
  List<FeatureAction> appActions(
    BuildContext context,
    FeatureContext feature,
  ) => [
    FeatureAction(
      id: 'clipboard.recent',
      label: context.clipboardL10n.recentClipsMenu,
      icon: LucideIcons.clipboardList,
      onPressed: () => unawaited(_openRecentClips(feature)),
    ),
  ];

  Future<void> _openRecentClips(FeatureContext feature) => feature.push<void>(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: RecentClipsPage(
        showsPreviewsFrom: feature.showsPreviewsFrom,
        openKeys: recentClipsKeys?.call(feature),
      ),
    ),
  );

  @override
  FeatureHealth? healthFor(FeatureContext feature, DeviceStatus device) {
    final session = device.session;
    if (session == null) {
      return null;
    }

    return clipboardHealthOf(
      _localizations(),
      session: session,
      name: device.device.name,
      sendsOnItsOwn: viewModel.sendsOnItsOwn,
    );
  }

  @override
  SettingsGroup get settingsGroup => .clipboard;

  @override
  Widget buildSettings(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const ClipboardSettingsFrame(),
      );

  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final l10n = context.clipboardL10n;

    return [
      FeatureSettings(
        group: settingsGroup,
        title: l10n.title,
        child: buildSettings(context, feature),
        summary: clipboardSummaryOf(
          l10n,
          sendsOnItsOwn: viewModel.sendsOnItsOwn,
          autoReceive: viewModel.autoReceive,
        ),
        isOn: viewModel.sendsOnItsOwn || viewModel.autoReceive,
        needsAttention: viewModel.lostBackgroundSend,
      ),
    ];
  }

  /// The tile has no screen to show a result on, so the outcome goes to a
  /// quiet notice instead.
  Future<void> _sendFromSystem(FeatureContext context, String? text) async {
    final result = switch (text) {
      final String text when text.isNotEmpty => await feature.sendText(text),
      _ => await feature.sendClipboard(),
    };

    final l10n = _localizations();
    await context.notifier.show(
      LocalNotice(
        id: _resultNoticeId,
        channel: switch (result) {
          .sent => NoticeChannel.transfers,
          _ => NoticeChannel.problems,
        },
        title: l10n.title,
        body: l10n.resultOf(result),
        silent: true,
      ),
    );
  }

  /// Text dragged onto a device lands on its clipboard.
  @override
  Future<Stream<FilesSendProgress>?> onTextDropped(
    FeatureContext feature,
    String text, {
    String? deviceId,
  }) async {
    final result = await this.feature.sendText(text, toDeviceId: deviceId);

    return Stream.value(switch (result) {
      .sent => const FilesSent(),
      _ => FilesSendFailed(_localizations().resultOf(result)),
    });
  }

  ClipboardLocalizations _localizations() => lookupClipboardLocalizations(
    AppLocale.pick(ClipboardLocalizations.supportedLocales),
  );

  /// Stops listening for the Android tile and releases the view model.
  Future<void> dispose() async {
    await _systemActions?.cancel();
    viewModel.dispose();
  }
}
