import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';

/// Settings → About: brings back the one-time tips for someone who waved
/// them off and forgot, or comes back to Ferret after months.
class TipsAgainRow extends StatefulWidget {
  const TipsAgainRow({super.key});

  @override
  State<TipsAgainRow> createState() => _TipsAgainRowState();
}

class _TipsAgainRowState extends State<TipsAgainRow> {
  bool _isBack = false;

  void _showAgain() {
    final settings = ShellScope.read(context).featureContext.engine.settings;

    unawaited(Tips(settings).showAgain());
    setState(() => _isBack = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.shellL10n;

    return Semantics(
      liveRegion: _isBack,
      child: GroupedRow(
        title: l10n.settingsTipsAgain,
        subtitle: switch (_isBack) {
          true => l10n.settingsTipsAgainDone,
          false => l10n.settingsTipsAgainDetail,
        },
        onTap: _showAgain,
      ),
    );
  }
}
