import 'dart:async';
import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:updates/feature/feature.dart';
import 'package:updates/l10n/l10n.dart';
import 'package:updates/services/services.dart';
import 'package:updates/ui/dialogs/dialogs.dart';
import 'package:updates/ui/frames/frames.dart';
import 'package:updates/ui/update_activity.dart';
import 'package:updates/view_models/view_models.dart';
import 'package:url_launcher/url_launcher.dart';

/// The app side of updates: a line under Needs you when a newer Ferret is
/// ready (What's new, Install), and the switch and Check now in About. Hidden
/// where an app store updates Ferret, such as on an iPhone.
class UpdatesFeatureUi extends FeatureUi {
  UpdatesFeatureUi({
    UpdatesFeature? feature,
    Future<UpdatePlatform> Function()? platform,
    UpdatesViewModel? viewModel,
    Future<bool> Function(Uri url)? openLink,
  }) : feature = feature ?? UpdatesFeature(),
       _platform = platform ?? UpdatePlatform.detect,
       _openLink = openLink ?? _launch {
    if (viewModel != null) {
      _use(viewModel);
    }
  }

  /// How long after launch the first check waits, so it never slows the
  /// start, and how often it looks whether a day has passed.
  static const firstCheck = Duration(seconds: 30);
  static const tick = Duration(hours: 1);

  @override
  final UpdatesFeature feature;

  final Future<UpdatePlatform> Function() _platform;
  final Future<bool> Function(Uri url) _openLink;
  final _changes = _Changes();
  UpdatesViewModel? _viewModel;
  Timer? _first;
  Timer? _ticker;
  AppLifecycleListener? _lifecycle;

  /// Null until the app started and the platform is known.
  UpdatesViewModel? get viewModel => _viewModel;

  @override
  String get featureId => UpdatesFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    UpdatesLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.updatesL10n.title;

  @override
  IconData get icon => LucideIcons.circleArrowUp;

  @override
  Listenable get uiChanges => _changes;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    if (_viewModel != null) {
      return;
    }

    final platform = await _platform();
    if (!platform.kind.checks) {
      return;
    }

    _use(
      UpdatesViewModel(
        platform: platform,
        currentVersion: context.engine.device.appVersion,
        settings: () => feature.settings,
        quit: () async {
          if (context.quit case final quit?) {
            await quit();
            return;
          }

          exit(0);
        },
      ),
    );
    void checkIfDue() => unawaited(
      _viewModel?.checkIfDue(paused: !context.engine.isRunning),
    );
    _first = Timer(firstCheck, checkIfDue);
    _ticker = Timer.periodic(tick, (_) => checkIfDue());
    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(_viewModel?.onResumed());
        checkIfDue();
      },
    );
  }

  @override
  bool hasHomeCard(FeatureContext feature) => false;

  @override
  List<ActivityItem> activity(BuildContext context, FeatureContext feature) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const [];
    }

    return [
      ?UpdateActivity.of(
        context.updatesL10n,
        viewModel,
        onWhatsNew: () => unawaited(_showWhatsNew(feature)),
        onDownloadPage: () => unawaited(_openPage()),
      ),
    ];
  }

  @override
  Widget? buildAboutSection(BuildContext context, FeatureContext feature) {
    final viewModel = _viewModel;
    if (viewModel == null || !viewModel.isOffered) {
      return null;
    }

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: UpdateAboutFrame(
        onWhatsNew: () => unawaited(_showWhatsNew(feature)),
      ),
    );
  }

  Future<void> _showWhatsNew(FeatureContext feature) async {
    final viewModel = _viewModel;
    final context = feature.navigatorKey.currentContext;
    if (viewModel == null || context == null) {
      return;
    }

    await WhatsNewDialog.show(context, viewModel: viewModel);
  }

  Future<void> _openPage() async {
    if (_viewModel case final viewModel?) {
      await _openLink(viewModel.downloadPage);
    }
  }

  void _use(UpdatesViewModel viewModel) {
    _viewModel = viewModel..addListener(_changes.changed);
    _changes.changed();
  }

  static Future<bool> _launch(Uri url) =>
      launchUrl(url, mode: .externalApplication);

  /// Stops the timers and releases the view model.
  void dispose() {
    _first?.cancel();
    _ticker?.cancel();
    _lifecycle?.dispose();
    _viewModel?.dispose();
    _changes.dispose();
  }
}

class _Changes extends ChangeNotifier {
  void changed() => notifyListeners();
}
