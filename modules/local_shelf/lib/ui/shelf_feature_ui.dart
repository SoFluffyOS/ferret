import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:local_shelf/feature/shelf_feature.dart';
import 'package:local_shelf/l10n/l10n.dart';
import 'package:local_shelf/models/models.dart';
import 'package:local_shelf/services/services.dart';
import 'package:local_shelf/ui/frames/frames.dart';
import 'package:local_shelf/ui/pages/pages.dart';
import 'package:local_shelf/ui/shelf_reach_host.dart';
import 'package:local_shelf/view_models/view_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

/// The shelf in the app: its box under the Mac popover's pages, and its
/// list page. Its files live in Ferret's cache folder, under `shelf`.
class ShelfFeatureUi extends FeatureUi {
  ShelfFeatureUi({ShelfFeature? feature, this.store, this.showsPreviewsFrom})
    : feature = feature ?? ShelfFeature();

  @override
  final ShelfFeature feature;

  /// Where the shelf keeps its things; the app's cache folder when null.
  final ShelfStore? store;

  /// Whether private things from a device may show here; the app's own
  /// answer when null.
  final bool Function(String deviceId)? showsPreviewsFrom;

  ShelfViewModel? _viewModel;
  ShelfReachViewModel? _reachViewModel;
  ShelfReachHost? _reach;
  StreamSubscription<String>? _settings;

  @override
  String get featureId => ShelfFeature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [
    ShelfLocalizations.delegate,
  ];

  @override
  String title(BuildContext context) => context.shelfL10n.title;

  @override
  IconData get icon => LucideIcons.inbox;

  @override
  bool hasHomeCard(FeatureContext feature) => false;

  @override
  Future<void> onAppStarted(FeatureContext context) async {
    final engine = context.engine;
    final viewModel = ShelfViewModel(
      localDeviceId: engine.identity.deviceId,
      showsPreviewsFrom: showsPreviewsFrom ?? context.showsPreviewsFrom,
      nameOf: engine.displayNameOf,
      dragOut: context.dragOut,
      quickLook: context.quickLook,
      settings: ShelfSettings(engine.settings),
    );
    _viewModel = viewModel;
    context.dropKeeper = viewModel;
    _reachViewModel = ShelfReachViewModel(
      store: engine.settings,
      runningApps: context.systemDrags?.runningApps,
    );
    await _startReach(context, viewModel);
    await _settings?.cancel();
    _settings = engine.settings.changes.listen(
      (_) => viewModel.previewsChanged(),
    );

    final store =
        this.store ?? ShelfStore(p.join((await AppPaths.get()).cache, 'shelf'));
    feature.use(store);
    final shelf = feature.store ?? store;
    await shelf.load();
    await feature.tidyOnLaunch();
    viewModel.attach(shelf);
  }

  /// The shelf over other apps while dragging, on a Mac.
  Future<void> _startReach(
    FeatureContext context,
    ShelfViewModel viewModel,
  ) async {
    final drags = context.systemDrags;
    final panel = context.floatingPanel;
    if (drags == null || panel == null || defaultTargetPlatform != .macOS) {
      return;
    }

    await _reach?.stop();
    final reach = ShelfReachHost(
      drags: drags,
      panel: panel,
      settings: ShelfSettings(context.engine.settings),
      viewModel: viewModel,
      onOpenList: () => unawaited(_openList(context, viewModel)),
    );
    _reach = reach;
    await reach.start();
  }

  Future<void> _openList(
    FeatureContext context,
    ShelfViewModel viewModel,
  ) async {
    await context.reveal();
    await context.push<void>(ShelfPage(viewModel: viewModel));
  }

  @override
  SettingsGroup get settingsGroup => .clipboard;

  /// Next to Clipboard in Settings, on a Mac only, where the shelf is.
  @override
  List<FeatureSettings> settingsSections(
    BuildContext context,
    FeatureContext feature,
  ) {
    final viewModel = _viewModel;
    if (viewModel == null || defaultTargetPlatform != .macOS) {
      return const [];
    }

    final l10n = context.shelfL10n;

    return [
      FeatureSettings(
        group: settingsGroup,
        title: l10n.title,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: viewModel),
            if (_reachViewModel case final reach?)
              ChangeNotifierProvider.value(value: reach),
          ],
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              const ShelfCopiesFrame(),
              if (_reachViewModel != null) const ShelfReachFrame(),
            ],
          ),
        ),
        summary: switch (viewModel.keepsCopies) {
          true => l10n.summaryCopies,
          false => l10n.summaryDropped,
        },
        isOn: viewModel.keepsCopies,
      ),
    ];
  }

  @override
  Widget? buildPopoverBar(BuildContext context, FeatureContext feature) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return null;
    }

    viewModel
      ..dragOut = feature.dragOut
      ..quickLook = feature.quickLook;

    return ChangeNotifierProvider.value(
      value: viewModel,
      child: ShelfPopoverBarFrame(
        trustStore: feature.engine.trustStore,
        child: ShelfBoxFrame(
          onOpenList: () =>
              unawaited(feature.push(ShelfPage(viewModel: viewModel))),
        ),
      ),
    );
  }
}
