import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

void main() {
  group('LocalNetworkViewModel', () {
    test(
      'an older Android, or Ferret not targeting 17, asks nothing',
      () async {
        final viewModel = LocalNetworkViewModel(system: _FakeSystem());

        await viewModel.refresh();

        expect(viewModel.asks, isFalse);
      },
    );

    test('Allow asks Android, and a yes looks for devices again', () async {
      final system = _FakeSystem()..access = .notGranted;
      final viewModel = LocalNetworkViewModel(system: system);
      await viewModel.refresh();
      expect(viewModel.asks, isTrue);

      system.answer = .granted;
      await viewModel.allow();

      expect(system.requests, 1);
      expect(viewModel.asks, isFalse);
      expect(system.changes, [NetworkChange.available]);
    });

    test('turned down for good, Allow opens Settings instead', () async {
      final system = _FakeSystem()..access = .notGranted;
      final viewModel = LocalNetworkViewModel(system: system);
      await viewModel.refresh();

      system.answer = .blocked;
      await viewModel.allow();
      expect(viewModel.isBlocked, isTrue);
      expect(system.settingsOpened, 0);

      await viewModel.allow();
      expect(system.requests, 1);
      expect(system.settingsOpened, 1);
      expect(system.changes, isEmpty);
    });

    test('allowed in Settings, coming back hides the ask', () async {
      final system = _FakeSystem()..access = .blocked;
      final viewModel = LocalNetworkViewModel(system: system);
      await viewModel.refresh();
      expect(viewModel.asks, isTrue);

      system.access = .granted;
      await viewModel.refresh();

      expect(viewModel.asks, isFalse);
      expect(system.changes, [NetworkChange.available]);
    });
  });

  group('LocalNetworkCard', () {
    testWidgets('says why, then Allow asks Android', (tester) async {
      final system = _FakeSystem()
        ..access = .notGranted
        ..answer = .granted;
      await tester.pumpWidget(testApp(LocalNetworkCard(system: system)));
      await tester.pumpAndSettle();

      expect(find.text('Find your devices'), findsOneWidget);
      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(system.requests, 1);
      expect(find.text('Find your devices'), findsNothing);
    });

    testWidgets('shows nothing when Android doesn\'t ask', (tester) async {
      await tester.pumpWidget(testApp(LocalNetworkCard(system: _FakeSystem())));
      await tester.pumpAndSettle();

      expect(find.text('Find your devices'), findsNothing);
    });
  });
}

class _FakeSystem extends Fake implements FerretSystem {
  LocalNetworkAccess access = .notNeeded;
  LocalNetworkAccess answer = .notGranted;
  int requests = 0;
  int settingsOpened = 0;
  final List<NetworkChange> changes = [];

  @override
  bool get isAndroid => true;

  @override
  Future<LocalNetworkAccess> localNetworkAccess() async => access;

  @override
  Future<LocalNetworkAccess> requestLocalNetworkAccess() async {
    requests++;
    return access = answer;
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  void onNetworkChange(NetworkChange change) => changes.add(change);
}
