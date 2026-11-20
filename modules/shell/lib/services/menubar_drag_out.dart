import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';

/// Drags out of Ferret through the Mac's menubar plugin, from the popover
/// or the desktop window.
class MenubarDragOut implements DragOut {
  const MenubarDragOut(this._menubar);

  final FerretMenubar _menubar;

  @override
  Future<bool> files(int viewId, List<String> paths) =>
      _menubar.startFileDrag(viewId, paths);

  @override
  Future<bool> promisedFiles(int viewId, List<PromisedFile> files) =>
      _menubar.startPromisedFileDrag(viewId, [
        for (final file in files)
          PromisedDragFile(
            name: file.name,
            image: file.image,
            fetch: file.fetch,
          ),
      ]);

  @override
  Future<bool> text(int viewId, String text, {bool isLink = false}) =>
      _menubar.startTextDrag(viewId, text, isLink: isLink);
}
