import 'package:media/media.dart';

/// Records the links "Continue here" opens; refuses schemes in [refused].
class FakeLinkOpener implements LinkOpener {
  FakeLinkOpener({this.refused = const {}});

  final Set<String> refused;
  final List<Uri> opened = [];
  final List<Uri> attempts = [];

  @override
  Future<bool> open(Uri uri) async {
    attempts.add(uri);
    if (refused.contains(uri.scheme)) {
      return false;
    }

    opened.add(uri);
    return true;
  }
}
