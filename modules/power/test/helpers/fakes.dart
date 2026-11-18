import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:ferret_power/ferret_power.dart';
import 'package:ferret_power/testing.dart';
import 'package:power/power.dart';

/// Just enough of the engine for the feature: its settings.
class FakeHost implements FeatureHost {
  FakeHost([Map<String, Object?>? settings])
    : settings = MemorySettingsStore(settings);

  @override
  final MemorySettingsStore settings;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A started feature on a fake phone.
class PowerHarness {
  PowerHarness._(this.phone, this.power, this.host, this.feature);

  static Future<PowerHarness> start({
    PowerStatus status = const PowerStatus(supported: true),
    Map<String, Object?>? settings,
  }) async {
    final phone = FakePowerPlatform(status: status);
    final power = PowerCapabilities.withPlatform(phone);
    final host = FakeHost(settings);
    final feature = PowerFeature(capabilities: () => power);
    await feature.start(host);
    await feature.ready;

    return PowerHarness._(phone, power, host, feature);
  }

  final FakePowerPlatform phone;
  final PowerCapabilities power;
  final FakeHost host;
  final PowerFeature feature;
  final List<Uri> openedLinks = [];
  bool linksOpen = true;

  late final PowerViewModel viewModel = PowerViewModel(
    feature,
    openLink: (link) async {
      openedLinks.add(link);
      return linksOpen;
    },
  );

  Future<void> dispose() async {
    viewModel.dispose();
    await feature.stop();
    await power.dispose();
  }
}

/// Lets queued stream events and futures run.
Future<void> settle() => Future<void>.delayed(Duration.zero);
