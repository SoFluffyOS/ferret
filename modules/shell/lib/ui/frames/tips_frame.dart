import 'dart:async';

import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/ui/widgets/widgets.dart';

/// The things worth trying first, one at a time, each shown once: copy and
/// paste across, then (on a Mac) dragging files onto the menubar icon. A
/// tip goes away for good when the person does the thing or waves it off.
class TipsFrame extends StatefulWidget {
  const TipsFrame({super.key, required this.device});

  /// The connected device the tips are about.
  final DeviceStatus device;

  /// Settings keys that remember a tip was shown.
  static const copyDoneKey = 'shell.tip_copy_done';
  static const dragDoneKey = 'shell.tip_drag_done';

  @override
  State<TipsFrame> createState() => _TipsFrameState();
}

class _TipsFrameState extends State<TipsFrame> {
  static const _clipboardId = 'clipboard';
  static const _dropId = 'drop';
  static const _goodbyeAfter = Duration(seconds: 3);

  late final SettingsStore _settings;
  late final Listenable _changes;
  late bool _copyDone;
  late bool _dragDone;
  bool _isSayingGoodbye = false;
  Timer? _goodbye;

  @override
  void initState() {
    super.initState();
    final scope = ShellScope.read(context);
    _settings = scope.featureContext.engine.settings;
    _copyDone = _settings.get<bool>(TipsFrame.copyDoneKey) ?? false;
    _dragDone = _settings.get<bool>(TipsFrame.dragDoneKey) ?? false;
    _changes = Listenable.merge([
      for (final feature in scope.features) ?feature.uiChanges,
    ])..addListener(_onActivity);
  }

  @override
  void dispose() {
    _changes.removeListener(_onActivity);
    _goodbye?.cancel();
    super.dispose();
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
