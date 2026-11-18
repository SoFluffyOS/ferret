import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('drags over the popover arrive in order as Dart events', () async {
    final menubar = FerretMenubar();
    final drags = <PopoverDrag>[];
    final subscription = menubar.drags.listen(drags.add);

    menubar
      ..onDragEntered(10, 20, 3)
      ..onDragUpdated(12, 24)
      ..onDragPerformed(['/tmp/a.txt'], 12, 24)
      ..onDragExited();
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
