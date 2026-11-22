/// Platform code for Ferret's drop feature: the Android share target and
/// file picker, the macOS Share menu, saving into Downloads through
/// MediaStore, opening or revealing received files, and the free space
/// where they land.
library;

export 'package:ferret_drop/src/content_files.dart';
export 'package:ferret_drop/src/ferret_drop.dart';
export 'package:ferret_drop/src/file_picks.dart';
export 'package:ferret_drop/src/free_space.dart';
export 'package:ferret_drop/src/messages.g.dart'
    show SavedFile, ShareTarget, SharedItems;
export 'package:ferret_drop/src/pending_downloads.dart';
