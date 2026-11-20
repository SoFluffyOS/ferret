import 'package:core/core.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';

void main() {
  test('out of the box: open on hover and shake on, the box off', () {
    final store = MemorySettingsStore();
    final reach = ShelfSettings(store).reach;
    final icon = MenubarDrops(store);

    expect(icon.springLoading, isTrue);
    expect(icon.iconDrop, IconDrop.sendToLast);
    expect(reach.shake, isTrue);
    expect(reach.sensitivity, ShakeSensitivity.normal);
    expect(reach.boxOnDrag, isFalse);
    expect(reach.boxShows, ShelfBoxShows.atEdge);
    expect(reach.shiftSummons, isFalse);
    expect(reach.ignoredApps, isEmpty);
    expect(reach.watchesDrags, isTrue);
  });

  test('nothing is watched once every way that needs it is off', () async {
    final settings = ShelfSettings(MemorySettingsStore());
    await settings.setShake(false);

    expect(settings.reach.watchesDrags, isFalse);

    await settings.setShiftSummons(true);
    expect(settings.reach.watchesDrags, isTrue);
  });

  test('choices are kept by name and unknown ones fall back', () async {
    final store = MemorySettingsStore({
      ShelfSettings.shakeSensitivityKey: 'ludicrous',
      MenubarDrops.iconDropKey: 'nowhere',
    });
    final settings = ShelfSettings(store);

    expect(settings.reach.sensitivity, ShakeSensitivity.normal);
    expect(MenubarDrops(store).iconDrop, IconDrop.sendToLast);

    await settings.setShakeSensitivity(.high);
    await settings.setBoxShows(.onDrag);
    await MenubarDrops(store).setIconDrop(.ask);

    expect(store.get<String>(ShelfSettings.shakeSensitivityKey), 'high');
    expect(settings.reach.boxShows, ShelfBoxShows.onDrag);
    expect(MenubarDrops(store).iconDrop, IconDrop.ask);
  });

  test('the view model adds and takes off ignored apps', () async {
    final store = MemorySettingsStore();
    final viewModel = ShelfReachViewModel(
      store: store,
      runningApps: () async => const [
        SystemApp(id: 'com.apple.Safari', name: 'Safari'),
        SystemApp(id: 'com.figma.Desktop', name: 'Figma'),
      ],
    );
    addTearDown(viewModel.dispose);
    var notified = 0;
    viewModel.addListener(() => notified++);

    await viewModel.loadApps();
    expect(viewModel.pickableApps.map((app) => app.name), ['Safari', 'Figma']);

    await viewModel.ignore(viewModel.pickableApps.first);
    await pumpEventQueue();
    expect(viewModel.options.ignores('com.apple.Safari'), isTrue);
    expect(viewModel.pickableApps.map((app) => app.name), ['Figma']);

    await viewModel.unignore(viewModel.options.ignoredApps.single);
    await pumpEventQueue();
    expect(viewModel.options.ignoredApps, isEmpty);
    expect(notified, greaterThan(1));
  });
}
