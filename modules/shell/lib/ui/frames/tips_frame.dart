import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// The things worth trying first, one at a time, each shown once: copy and
/// paste across, then (on a Mac) dragging files onto the menubar icon. On
/// an iPhone, the first Send clipboard brings up how to stop iOS asking
/// "Allow Paste" every time. A tip goes away for good when the person does
/// the thing or waves it off.
class TipsFrame extends StatefulWidget {
  const TipsFrame({super.key, required this.device});

  /// The connected device the tips are about.
  final DeviceStatus device;

  /// Settings keys that remember a tip was shown.
  static const copyDoneKey = 'shell.tip_copy_done';
  static const dragDoneKey = 'shell.tip_drag_done';
  static const pasteDoneKey = 'shell.tip_paste_done';

  @override
  State<TipsFrame> createState() => _TipsFrameState();
}

class _TipsFrameState extends State<TipsFrame> {
  static const _clipboardId = 'clipboard';
  static const _dropId = 'drop';
  static const _sendClipboardId = 'clipboard.send';
  static final _appSettings = Uri.parse('app-settings:');
  static const _goodbyeAfter = Duration(seconds: 3);

  late final SettingsStore _settings;
  late final Listenable _changes;
  late bool _copyDone;
  late bool _dragDone;
  late bool _pasteDone;
  late bool _hasReadClipboard;
  bool _isSayingGoodbye = false;
  Timer? _goodbye;
  StreamSubscription<String>? _settingChanges;

  @override
  void initState() {
    super.initState();
    final scope = ShellScope.read(context);
    _settings = scope.featureContext.engine.settings;
    _copyDone = _settings.get<bool>(TipsFrame.copyDoneKey) ?? false;
    _dragDone = _settings.get<bool>(TipsFrame.dragDoneKey) ?? false;
    _pasteDone = _settings.get<bool>(TipsFrame.pasteDoneKey) ?? false;
    _hasReadClipboard = _sentClipboardBefore(scope);
    if (_asksBeforePaste && !_pasteDone && !_hasReadClipboard) {
      _settingChanges = _settings.changes.listen(_onSettingChanged);
    }
    _changes = Listenable.merge([
      for (final feature in scope.features) ?feature.uiChanges,
    ])..addListener(_onActivity);
  }

  @override
  void dispose() {
    _changes.removeListener(_onActivity);
    _goodbye?.cancel();
    unawaited(_settingChanges?.cancel());
    super.dispose();
  }

  /// iOS asks before every read of the clipboard by another app's copy.
  bool get _asksBeforePaste => defaultTargetPlatform == .iOS;

  bool _sentClipboardBefore(ShellScope scope) {
    final usage = DeviceActionUsage(_settings);
    return scope.featureContext.engine.trustStore.devices.any(
      (device) => (usage.countsFor(device.id)[_sendClipboardId] ?? 0) > 0,
    );
  }

  /// Send clipboard counts its use when pressed, which is when iOS asks.
  void _onSettingChanged(String key) {
    if (!mounted || !key.startsWith(DeviceActionUsage.keyPrefix)) {
      return;
    }

    final usage = DeviceActionUsage(_settings);
    final deviceId = key.substring(DeviceActionUsage.keyPrefix.length);
    if ((usage.countsFor(deviceId)[_sendClipboardId] ?? 0) == 0) {
      return;
    }

    unawaited(_settingChanges?.cancel());
    _settingChanges = null;
    setState(() => _hasReadClipboard = true);
  }

  void _finishPaste() {
    unawaited(_settings.set(TipsFrame.pasteDoneKey, true));
    setState(() => _pasteDone = true);
  }

  void _openPasteSettings() {
    unawaited(launchUrl(_appSettings));
    _finishPaste();
  }

  /// Doing the thing is the best way to dismiss a tip about it.
  void _onActivity() {
    if (!mounted) {
      return;
    }

    if (!_copyDone && _hasTrace(_clipboardId)) {
      _finishCopy(didIt: true);
      return;
    }

    if (_copyDone && !_dragDone && _hasTrace(_dropId)) {
      _finishDrag();
    }
  }

  bool _hasTrace(String featureId) {
    final scope = ShellScope.read(context);
    return scope.features.any(
      (feature) =>
          feature.featureId == featureId &&
          feature.activity(context, scope.featureContext).isNotEmpty,
    );
  }

  void _finishCopy({required bool didIt}) {
    unawaited(_settings.set(TipsFrame.copyDoneKey, true));
    setState(() {
      _copyDone = true;
      _isSayingGoodbye = didIt;
    });
    if (!didIt) {
      return;
    }

    _goodbye = Timer(
      _goodbyeAfter,
      () => setState(() => _isSayingGoodbye = false),
    );
  }

  void _finishDrag() {
    unawaited(_settings.set(TipsFrame.dragDoneKey, true));
    setState(() => _dragDone = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;
    final name = widget.device.device.name;

    if (_isSayingGoodbye) {
      return TipRow(icon: LucideIcons.check, text: l10n.tipDone);
    }

    if (_asksBeforePaste && _hasReadClipboard && !_pasteDone) {
      return TipRow(
        icon: LucideIcons.clipboardCheck,
        text: l10n.tipPaste,
        actionLabel: l10n.tipPasteOpen,
        onAction: _openPasteSettings,
        dismissLabel: l10n.tipDismiss,
        onDismiss: _finishPaste,
      );
    }

    if (!_copyDone) {
      return TipRow(
        icon: LucideIcons.clipboard,
        text: switch (_copiesHere) {
          true => l10n.tipCopyHere(name),
          false => l10n.tipCopyThere(name),
        },
        dismissLabel: l10n.tipDismiss,
        onDismiss: () => _finishCopy(didIt: false),
      );
    }

    if (!_dragDone && defaultTargetPlatform == .macOS) {
      return TipRow(
        icon: LucideIcons.arrowLeftRight,
        text: l10n.tipDrag,
        dismissLabel: l10n.tipDismiss,
        onDismiss: _finishDrag,
      );
    }

    return const SizedBox.shrink();
  }

  /// A computer notices every copy by itself; a phone often can't, so
  /// there the sure direction is copying on the other device.
  bool get _copiesHere => switch (defaultTargetPlatform) {
    .macOS || .windows || .linux => true,
    _ => false,
  };
}
