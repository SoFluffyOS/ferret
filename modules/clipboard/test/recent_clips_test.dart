import 'package:clipboard/clipboard.dart';
import 'package:clipboard/services/services.dart';
import 'package:clipboard/ui/frames/frames.dart';
import 'package:clipboard/ui/widgets/widgets.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

class _NoDragOut implements DragOut {
  @override
  Future<bool> files(int viewId, List<String> paths) async => false;

  @override
  Future<bool> promisedFiles(int viewId, List<PromisedFile> files) async =>
      false;

  @override
  Future<bool> text(int viewId, String text, {bool isLink = false}) async =>
      false;
}

void main() {
  late FakeClipboard clipboard;
  late FakeHost host;
  late FakeSession pixel;
  late ClipboardFeature feature;
  late ClipboardViewModel viewModel;

  Future<void> start(WidgetTester tester) async {
    await tester.runAsync(() async {
      clipboard = FakeClipboard();
      host = await FakeHost.create(
        settings: {ClipboardSettings.syncSensitiveKey: true},
      );
      pixel = FakeSession('pixelpixelpixelp');
      host.sessions = [pixel];
      feature = ClipboardFeature(clipboard: () => clipboard);
      await feature.start(host);
    });
    viewModel = ClipboardViewModel(feature);
    addTearDown(() async {
      viewModel.dispose();
      await feature.stop();
    });
  }

  Future<void> receive(
    WidgetTester tester,
    String text, {
    required String id,
    bool sensitive = false,
  }) => tester.runAsync(
    () => feature.onEnvelope(
      pixel,
      envelopeOf(pushOf(text, id: id, sensitive: sensitive)),
    ),
  );

  Widget recentClips({
    bool showsPreviews = true,
    String? openKeys,
    ClipDrags? drags,
  }) => testApp(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: SingleChildScrollView(
        child: RecentClipsFrame(
          showsPreviewsFrom: (_) => showsPreviews,
          openKeys: openKeys,
          drags: drags,
        ),
      ),
    ),
  );

  ClipDrags drags() =>
      ClipDrags(dragOut: _NoDragOut(), folder: () async => '/tmp');

  testWidgets('clips drag out where the computer can, never hidden ones', (
    tester,
  ) async {
    await start(tester);
    await receive(tester, 'first', id: 'a');

    await tester.pumpWidget(recentClips(drags: drags()));

    expect(
      find.text('Drag one into any app to drop it there.'),
      findsOneWidget,
    );
    expect(
      tester.widget<RecentClipRow>(find.byType(RecentClipRow)).onDragStart,
      isNotNull,
    );

    await tester.pumpWidget(recentClips(drags: drags(), showsPreviews: false));

    expect(
      tester.widget<RecentClipRow>(find.byType(RecentClipRow)).onDragStart,
      isNull,
    );

    await tester.pumpWidget(recentClips());

    expect(find.textContaining('Drag one'), findsNothing);
  });

  testWidgets('says which keys open it from any app, when there are some', (
    tester,
  ) async {
    await start(tester);
    await receive(tester, 'first', id: 'a');

    await tester.pumpWidget(recentClips(openKeys: '⌃⌥V'));

    expect(find.text('Open this from any app with ⌃⌥V.'), findsOneWidget);

    await tester.pumpWidget(recentClips());

    expect(find.textContaining('from any app'), findsNothing);
  });

  testWidgets('says so when nothing was copied yet', (tester) async {
    await start(tester);

    await tester.pumpWidget(recentClips());

    expect(find.textContaining('Nothing copied yet'), findsOneWidget);
  });

  testWidgets('lists clips newest first and leaves private ones out', (
    tester,
  ) async {
    await start(tester);
    await receive(tester, 'first', id: 'a');
    await receive(tester, 'hunter2', id: 'b', sensitive: true);
    await receive(tester, 'second', id: 'c');

    await tester.pumpWidget(recentClips());

    expect(viewModel.recentClips.map((clip) => clip.id), ['c', 'a']);
    expect(find.text('second'), findsOneWidget);
    expect(find.text('first'), findsOneWidget);
    expect(find.text('hunter2'), findsNothing);
    expect(find.text('From Pixel'), findsNWidgets(2));
  });

  testWidgets('Copy puts an older clip back on the clipboard', (tester) async {
    await start(tester);
    await receive(tester, 'first', id: 'a');
    await receive(tester, 'second', id: 'c');
    await tester.pumpWidget(recentClips());

    await tester.runAsync(() async {
      await tester.tap(find.text('Copy').last);
      await settle();
    });
    await tester.pump();

    expect(clipboard.writes.last.text, 'first');
    expect(find.text('Copied'), findsOneWidget);
  });

  testWidgets('hidden previews show where a clip came from, not what', (
    tester,
  ) async {
    await start(tester);
    await receive(tester, 'secret plan', id: 'a');

    await tester.pumpWidget(recentClips(showsPreviews: false));

    expect(find.text('secret plan'), findsNothing);
    expect(find.text('Copied on Pixel'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });
}
