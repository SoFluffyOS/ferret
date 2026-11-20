import 'package:feature_kit/feature_kit.dart';

/// Records what would be dragged out.
class FakeDragOut implements DragOut {
  final List<List<String>> fileDrags = [];
  final List<(String, bool)> texts = [];

  @override
  Future<bool> files(int viewId, List<String> paths) async {
    fileDrags.add(paths);
    return true;
  }

  @override
  Future<bool> promisedFiles(int viewId, List<PromisedFile> files) async =>
      false;

  @override
  Future<bool> text(int viewId, String text, {bool isLink = false}) async {
    texts.add((text, isLink));
    return true;
  }
}
