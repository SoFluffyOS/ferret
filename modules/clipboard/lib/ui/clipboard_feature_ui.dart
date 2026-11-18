import 'dart:async';
import 'dart:io';

import 'package:clipboard/feature/clipboard_feature.dart';
import 'package:clipboard/l10n/l10n.dart';
import 'package:clipboard/ui/frames/frames.dart';
import 'package:clipboard/ui/widgets/widgets.dart';
import 'package:clipboard/view_models/clipboard_view_model.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// The app side of Clipboard: the home card, "Send clipboard" for each
/// device, the Settings section, and the Android tile and notification
/// action.
class ClipboardFeatureUi extends FeatureUi {
  ClipboardFeatureUi({ClipboardFeature? feature})
    : feature = feature ?? ClipboardFeature();

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
    if (!Platform.isAndroid) {
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

  @override
  Widget? buildHomeCard(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const ClipboardCardFrame(),
      );

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
        label: context.clipboardL10n.sendClipboard,
        icon: LucideIcons.clipboardCopy,
        onPressed: () =>
            unawaited(viewModel.sendClipboard(toDeviceId: device.device.id)),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) =>
      ChangeNotifierProvider.value(
        value: viewModel,
        child: const ClipboardSettingsFrame(),
      );

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

  ClipboardLocalizations _localizations() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final supported = ClipboardLocalizations.supportedLocales.any(
      (candidate) => candidate.languageCode == locale.languageCode,
    );
    if (supported) {
      return lookupClipboardLocalizations(Locale(locale.languageCode));
    }

    return lookupClipboardLocalizations(
      ClipboardLocalizations.supportedLocales.first,
    );
  }

  /// Stops listening for the Android tile and releases the view model.
  Future<void> dispose() async {
    await _systemActions?.cancel();
    viewModel.dispose();
  }
}
