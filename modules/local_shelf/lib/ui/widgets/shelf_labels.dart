import 'package:local_shelf/l10n/l10n.dart';
import 'package:local_shelf/models/models.dart';

/// Words for shelf items on screen.
abstract final class ShelfLabels {
  /// What [item] is called: its name, or what it is when it has none,
  /// such as a copied picture.
  static String nameOf(ShelfLocalizations l10n, ShelfItem item) {
    if (item.name.isNotEmpty) {
      return item.name;
    }

    return kindOf(l10n, item.kind);
  }

  static String kindOf(ShelfLocalizations l10n, ShelfKind kind) =>
      switch (kind) {
        .file => l10n.kindFile,
        .folder => l10n.kindFolder,
        .image => l10n.kindImage,
        .text => l10n.kindText,
        .link => l10n.kindLink,
      };
}
