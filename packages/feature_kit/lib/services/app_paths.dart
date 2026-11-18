import 'package:core/core.dart';
import 'package:path_provider/path_provider.dart';

/// This app's [FerretPaths], found once: `~/.sofluffy/ferret` on computers,
/// the app support folder on phones.
abstract final class AppPaths {
  static FerretPaths? _paths;

  // Not a cached Future: a finished Future runs its listeners in the zone
  // that made it, which stalls callers in another zone, as in widget tests.
  static Future<FerretPaths> get() async =>
      _paths ??= await FerretPaths.resolve(
        phoneDirectory: () async =>
            (await getApplicationSupportDirectory()).path,
      );

  /// Points the app at [paths] instead, so tests never write to the real
  /// home folder.
  static void use(FerretPaths paths) => _paths = paths;
}
