import 'dart:io';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
// The pigeon API is what a fake of the Mac side implements.
// ignore: implementation_imports
import 'package:ferret_menubar/src/messages.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shell/shell.dart';

import 'test_app.dart';

class _FakeMenubarApi implements MenubarHostApi {
  final List<List<String>> previewed = [];
  final List<(int, List<String>)> dragged = [];

  @override
  Future<void> toggleQuickLook(List<String> paths) async =>
      previewed.add(paths);

  @override
  Future<bool> startFileDrag(int viewId, List<String> paths) async {
    dragged.add((viewId, paths));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeMenubarApi api;

  Widget line(ActivityItem item) => Provider<FerretMenubar>.value(
    value: FerretMenubar(api: api),
    child: testApp(
      KeyboardLines(
        child: Column(
          mainAxisSize: .min,
          children: [ActivityRow(item: item, now: DateTime(2026, 11, 19))],
        ),
      ),
    ),
  );

  setUp(() => api = _FakeMenubarApi());

  testWidgets(
    'Space shows a received file in Quick Look, a drag takes it out',
    (tester) async {
      await tester.pumpWidget(
        line(
          const ActivityItem(
            id: 'drop.1',
            icon: LucideIcons.arrowDown,
            title: 'IMG_2041.jpg from Pixel 9',
            files: ['/Users/me/Downloads/IMG_2041.jpg'],
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.drag(
        find.text('IMG_2041.jpg from Pixel 9'),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();

      expect(api.previewed, [
        ['/Users/me/Downloads/IMG_2041.jpg'],
      ]);
      expect(api.dragged.single.$2, ['/Users/me/Downloads/IMG_2041.jpg']);
    },
    skip: !Platform.isMacOS,
  );

  testWidgets('a line about no file has nothing to preview or drag', (
    tester,
  ) async {
    await tester.pumpWidget(
      line(
        const ActivityItem(
          id: 'clip.1',
          icon: LucideIcons.clipboard,
          title: 'Copied on Pixel 9',
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.drag(find.text('Copied on Pixel 9'), const Offset(80, 0));
    await tester.pumpAndSettle();

    expect(api.previewed, isEmpty);
    expect(api.dragged, isEmpty);
  });
}
