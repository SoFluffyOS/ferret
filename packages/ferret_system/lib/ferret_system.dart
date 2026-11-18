/// System hooks Ferret needs: the Android foreground service, Quick Settings
/// tile and battery settings, and network and wake events for reconnecting.
library;

export 'package:ferret_system/src/desktop/desktop.dart';
export 'package:ferret_system/src/device_maker.dart';
export 'package:ferret_system/src/ferret_system.dart';
export 'package:ferret_system/src/messages.g.dart'
    show AddTileResult, NetworkChange;
export 'package:ferret_system/src/pause_state.dart';
export 'package:ferret_system/src/polling_network_watcher.dart';
export 'package:ferret_system/src/system_action.dart';
export 'package:ferret_system/src/system_platform.dart';
