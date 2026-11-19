import 'package:core/core.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart';
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'test_app.dart';

void main() {
  late MemorySettingsStore settings;
  late DeviceAccess access;
  late DeviceAccessViewModel viewModel;

  setUp(() {
    settings = MemorySettingsStore();
    access = DeviceAccess(settings);
    viewModel = DeviceAccessViewModel(
      access: access,
      deviceId: 'pixel',
      featureIds: const ['clipboard', 'notifications', 'drop'],
    );
  });

  tearDown(() => viewModel.dispose());

  group('DeviceAccessViewModel', () {
    test('everything is allowed until turned off', () {
      expect(viewModel.isAllowed('clipboard'), isTrue);
      expect(viewModel.offCount, 0);
      expect(viewModel.allOff, isFalse);
    });

    test('turning one off is saved for that device only', () async {
      await viewModel.setAllowed('clipboard', false);

      expect(viewModel.isAllowed('clipboard'), isFalse);
      expect(access.isBlocked('pixel', 'clipboard'), isTrue);
      expect(access.isBlocked('laptop', 'clipboard'), isFalse);
      expect(settings.get<Map<String, Object?>>(DeviceAccess.blockedKey), {
        'pixel': ['clipboard'],
      });
    });

    test('turn everything off, then back on, in one tap each', () async {
      var notified = 0;
      viewModel.addListener(() => notified++);

      await viewModel.turnAllOff();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.allOff, isTrue);
      expect(notified, 1);

      await viewModel.turnAllOn();
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.offCount, 0);
      expect(access.blockedFor('pixel'), isEmpty);
      expect(notified, 2);
    });
  });

  testWidgets('each feature has a switch that turns it off for the device', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider.value(
          value: viewModel,
          child: SingleChildScrollView(
            child: DeviceAccessFrame(
              deviceName: 'Pixel 7',
              here: 'this Mac',
              isConnected: false,
              features: [
                _Ui('clipboard', 'Clipboard'),
                _Ui('notifications', 'Notifications'),
                _Ui('drop', 'Drop'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('What you copy, both ways'), findsOneWidget);
    expect(find.textContaining('Pixel 7 is offline'), findsOneWidget);

    await tester.tap(find.byType(SwitchToggle).first);
    await tester.pumpAndSettle();

    expect(access.isBlocked('pixel', 'clipboard'), isTrue);

    await tester.tap(find.text('Turn everything off'));
    await tester.pumpAndSettle();

    expect(viewModel.allOff, isTrue);
    expect(find.text('Turn everything back on'), findsOneWidget);
  });
}

class _NoFeature extends Feature {
  _NoFeature(this.id);

  @override
  final String id;

  @override
  Future<Null> onEnvelope(Session session, Envelope envelope) async => null;
}

class _Ui extends FeatureUi {
  _Ui(this.featureId, this._title) : feature = _NoFeature(featureId);

  @override
  final String featureId;

  @override
  final Feature feature;

  final String _title;

  @override
  String title(BuildContext context) => _title;

  @override
  IconData get icon => LucideIcons.clipboard;
}
