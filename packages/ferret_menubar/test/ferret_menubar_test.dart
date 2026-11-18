import 'dart:io';

import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:ferret_menubar/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingApi implements MenubarHostApi {
  final List<(MenubarIconState, double, String)> icons = [];

  @override
  Future<void> setIconState(
    MenubarIconState state,
    double progress,
    String tooltip,
  ) async => icons.add((state, progress, tooltip));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the icon state reaches the Mac with its progress kept within 0 to 1',
    () async {
      final api = _RecordingApi();
      final menubar = FerretMenubar(api: api);

      await menubar.setIconState(.paused, tooltip: 'Ferret · Paused');
      await menubar.setIconState(.working, progress: 0.4);
      await menubar.setIconState(.working, progress: 1.7);

      expect(api.icons, [
        (MenubarIconState.paused, 0.0, 'Ferret · Paused'),
        (MenubarIconState.working, 0.4, 'Ferret'),
        (MenubarIconState.working, 1.0, 'Ferret'),
      ]);
    },
    skip: !Platform.isMacOS,
  );

  test('drags over the popover arrive in order as Dart events', () async {
    final menubar = FerretMenubar();
    final drags = <PopoverDrag>[];
    final subscription = menubar.drags.listen(drags.add);

    menubar
      ..onDragEntered(7, 10, 20, 3)
      ..onDragUpdated(7, 12, 24)
      ..onDragPerformed(7, ['/tmp/a.txt'], 12, 24)
      ..onDragExited(7);
    await pumpEventQueue();

    expect(drags, hasLength(4));
    expect(
      drags.first,
      isA<PopoverDragEntered>()
          .having((drag) => drag.position, 'position', const Offset(10, 20))
          .having((drag) => drag.fileCount, 'fileCount', 3),
    );
    expect(
      drags[1],
      isA<PopoverDragMoved>().having(
        (drag) => drag.position,
        'position',
        const Offset(12, 24),
      ),
    );
    expect(
      drags[2],
      isA<PopoverDragDropped>().having(
        (drag) => drag.paths,
        'paths',
        ['/tmp/a.txt'],
      ),
    );
    expect(drags.last, isA<PopoverDragExited>());
    await subscription.cancel();
  });
}
