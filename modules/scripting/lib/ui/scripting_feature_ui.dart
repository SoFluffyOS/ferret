import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:scripting/feature/feature.dart';
import 'package:scripting/l10n/l10n.dart';
import 'package:scripting/models/models.dart';
import 'package:scripting/services/services.dart';
import 'package:scripting/ui/frames/frames.dart';
import 'package:scripting/view_models/view_models.dart';

/// The app side of scripting: shows notices that scripts on your other
/// computers send (once you allowed that computer on its page), runs hook
/// scripts on a computer, and lists them in Settings.
class ScriptingFeatureUi extends FeatureUi {
  ScriptingFeatureUi({ScriptingFeature? feature, HookRunner? hooks})
    : feature = feature ?? ScriptingFeature(),
      _hooks = hooks;

  @override
  final ScriptingFeature feature;

  HookRunner? _hooks;
  ScriptingViewModel? _viewModel;
  StreamSubscription<ScriptNoticeArrived>? _notices;
  var _noticeCount = 0;

  static bool get _isComputer => switch (defaultTargetPlatform) {
    .macOS || .windows || .linux => true,
    _ => false,
  };

  @override
  String get featureId => ScriptingFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    ScriptingLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.scriptingL10n.title;

  @override
  IconData get icon => LucideIcons.squareTerminal;

  @override
  SettingsGroup get settingsGroup => .otherApps;

  @override
  bool hasHomeCard(FeatureContext feature) => false;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    await _notices?.cancel();
    _notices = feature.notices.listen(
      (notice) => unawaited(_show(context.notifier, notice)),
    );
    if (!_isComputer) {
      return;
    }

    final hooks =
        _hooks ??
        HookRunner(p.join((await AppPaths.get()).root, HookRunner.folderName));
    _hooks = hooks;
    hooks.attach(feature.events.events);
    final viewModel = ScriptingViewModel(hooks);
    _viewModel = viewModel;
    await viewModel.refresh();
  }

  Future<void> _show(LocalNotifier notifier, ScriptNoticeArrived notice) {
    final l10n = lookupScriptingLocalizations(
      AppLocale.pick(ScriptingLocalizations.supportedLocales),
    );
    _noticeCount++;
    final title = switch (notice.title.isEmpty) {
      true => notice.deviceName,
      false => l10n.noticeTitle(notice.title, notice.deviceName),
    };

    return notifier.show(
      LocalNotice(
        id: '$featureId.${notice.deviceId}.$_noticeCount',
        channel: .incoming,
        title: title,
        body: notice.body,
        groupKey: '$featureId.${notice.deviceId}',
        private: PrivateContent(
          notice.deviceId,
          cover: l10n.noticeCover(notice.deviceName),
        ),
      ),
    );
  }

  @override
  List<DevicePermission> devicePermissions(
    BuildContext context,
    FeatureContext feature,
    DeviceStatus device,
  ) {
    final deviceId = device.device.id;
    final settings = this.feature.settings;
    final isComputer = device.device.formFactor == .FORM_FACTOR_DESKTOP;
    if (!isComputer && !settings.allowsNotices(deviceId)) {
      return const [];
    }

    final l10n = context.scriptingL10n;
    return [
      DevicePermission(
        label: l10n.permissionLabel(device.device.name),
        detail: l10n.permissionDetail,
        value: settings.allowsNotices(deviceId),
        onChanged: (value) => unawaited(
          settings.setAllowsNotices(deviceId, allowed: value),
        ),
      ),
    ];
  }

  @override
  Widget? buildSettings(BuildContext context, FeatureContext feature) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: const ScriptingSettingsFrame(),
    );
  }
}
