import 'package:jaspr_content/jaspr_content.dart';
import 'package:path/path.dart' as p;

/// Loads `docs` like [FilesystemLoader], but serves every page under
/// [prefix], so the landing page can own `/` and the docs live at `/docs/...`.
/// The Markdown stays where it is; only the routes move. Only `.md` files are
/// pages: images under `assets/` are served as files.
class DocsLoader extends FilesystemLoader {
  DocsLoader(super.directory, {this.prefix = 'docs'})
    : super(filterExtensions: const {'.md'});

  final String prefix;

  @override
  Future<List<FilePageSource>> loadPageSources() async => [
    for (final source in await super.loadPageSources()) _prefixed(source),
  ];

  @override
  void addSource(FilePageSource source) => super.addSource(_prefixed(source));

  FilePageSource _prefixed(FilePageSource source) =>
      FilePageSource(p.posix.join(prefix, source.path), source.file, this);
}
