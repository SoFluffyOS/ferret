import 'package:core/core.dart';
import 'package:path_provider/path_provider.dart';

/// This app's [FerretPaths], found once: `~/.sofluffy/ferret` on computers,
/// the app support folder on phones.
abstract final class AppPaths {
  static Future<FerretPaths>? _paths;

  static Future<FerretPaths> get() => _paths ??= FerretPaths.resolve(
    phoneDirectory: () async => (await getApplicationSupportDirectory()).path,
  );

  /// Points the app at [paths] instead, so tests never write to the real
  /// home folder.
  static void use(FerretPaths paths) => _paths = Future.value(paths);
}
