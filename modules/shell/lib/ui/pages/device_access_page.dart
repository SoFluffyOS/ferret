import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/models/models.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/view_models/view_models.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// What one paired device can use on this one, feature by feature, each
/// with a switch that stops it right away.
class DeviceAccessPage extends StatefulWidget {
  const DeviceAccessPage({super.key, required this.deviceId});

  final String deviceId;

  /// The features on this device that the paired [deviceId] can reach,
  /// in Settings order: only those that do something between the two,
  /// such as no texts or calls between a Mac and an iPhone.
  static List<FeatureUi> listedFeatures(
    List<FeatureUi> features,
    FerretEngine engine,
    String deviceId,
  ) {
    final available = {
      for (final feature in engine.features)
        if (feature.isAvailable) feature.id,
    };
    final here = engine.device.platform;
    final there = engine.trustStore[deviceId]?.platform;

    return [
      for (final feature in features)
        if (available.contains(feature.featureId) &&
            !FeatureAccess.localOnly.contains(feature.featureId) &&
            (there == null ||
                FeatureAccess.reaches(feature.featureId, here, there)))
          feature,
    ];
  }

  /// A few words for the device's page: "Everything on", "2 of 9 off".
  static String summary(
    BuildContext context,
    List<FeatureUi> features,
    FerretEngine engine,
    String deviceId,
  ) {
    final l10n = context.shellL10n;
    final listed = listedFeatures(features, engine, deviceId);
    final off = listed
        .where(
          (feature) => engine.access.isBlocked(deviceId, feature.featureId),
        )
        .length;

    if (off == 0) {
      return l10n.accessSummaryAll;
    }

    if (off == listed.length) {
      return l10n.accessSummaryNone;
    }

    return l10n.accessSummarySome(off, listed.length);
  }

  @override
  State<DeviceAccessPage> createState() => _DeviceAccessPageState();
}

class _DeviceAccessPageState extends State<DeviceAccessPage> {
  late final List<FeatureUi> _features;
  late final DeviceAccessViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final scope = ShellScope.read(context);
    final engine = scope.featureContext.engine;
    _features = DeviceAccessPage.listedFeatures(
      scope.features,
      engine,
      widget.deviceId,
    );
    _viewModel = DeviceAccessViewModel(
      access: engine.access,
      deviceId: widget.deviceId,
      featureIds: [for (final feature in _features) feature.featureId],
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;
    final status = context.select<EngineHost, DeviceStatus?>(
      (host) => host.statusOf(widget.deviceId),
    );
    final l10n = context.shellL10n;
    final name = status?.device.name ?? '';

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: FerretPage(
        title: l10n.accessTitle(name),
        backLabel: l10n.back,
        width: .narrow,
        children: [
          DeviceAccessFrame(
            deviceName: name,
            here: l10n.here(engine.device),
            isConnected: status?.isConnected ?? false,
            features: _features,
          ),
          if (engine.device.formFactor != .FORM_FACTOR_PHONE) ...[
            Spacing.v24,
            PrivatePreviewsCard(
              previews: PrivatePreviews(engine.settings),
              deviceId: widget.deviceId,
              deviceName: name,
            ),
          ],
        ],
      ),
    );
  }
}
