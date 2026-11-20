/// Runs a Flutter app from the macOS menubar in a detachable popover, with
/// a desktop window next to it on the same engine.
library;

export 'package:ferret_menubar/src/ferret_menubar.dart';
export 'package:ferret_menubar/src/messages.g.dart'
    show
        MenubarApp,
        MenubarDockMode,
        MenubarDragKind,
        MenubarDragPoint,
        MenubarIconState,
        MenubarMenuItem,
        MenubarPanelMotion,
        MenubarScreen,
        MenubarShortcut,
        MenubarSystemDrag;
export 'package:ferret_menubar/src/popover_drag.dart';
export 'package:ferret_menubar/src/system_drag.dart';
export 'package:ferret_menubar/src/window_event.dart';
