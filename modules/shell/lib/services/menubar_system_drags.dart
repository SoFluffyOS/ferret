import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';

/// Drags in other apps, as the Mac's menubar plugin sees them.
class MenubarSystemDrags implements SystemDrags {
  const MenubarSystemDrags(this._menubar);

  final FerretMenubar _menubar;

  @override
  Stream<SystemDragEvent> get events => _menubar.systemDrags.map(convert);

  @override
  Future<void> watch({required bool on}) => _menubar.watchSystemDrags(on: on);

  @override
  Future<List<SystemApp>> runningApps() async => [
    for (final app in await _menubar.runningApps())
      SystemApp(id: app.bundleId, name: app.name),
  ];

  static SystemDragEvent convert(MenubarSystemDragEvent event) =>
      switch (event) {
        MenubarSystemDragStarted(:final drag) => SystemDragStarted(
          kind: switch (drag.kind) {
            .files => .files,
            .text => .text,
            .link => .link,
          },
          sourceApp: drag.sourceApp,
          position: Offset(drag.point.x, drag.point.y),
          screen: screenOf(drag.point.screen),
          fn: drag.point.fn,
          shift: drag.point.shift,
        ),
        MenubarSystemDragMoved(:final point) => SystemDragMoved(
          position: Offset(point.x, point.y),
          screen: screenOf(point.screen),
          fn: point.fn,
          shift: point.shift,
        ),
        MenubarSystemDragEnded() => const SystemDragEnded(),
      };

  static SystemScreen screenOf(MenubarScreen screen) => SystemScreen(
    frame: Rect.fromLTWH(screen.x, screen.y, screen.width, screen.height),
    visible: Rect.fromLTWH(
      screen.visibleX,
      screen.visibleY,
      screen.visibleWidth,
      screen.visibleHeight,
    ),
  );
}
