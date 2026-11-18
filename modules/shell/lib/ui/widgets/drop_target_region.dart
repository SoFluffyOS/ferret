import 'package:flutter/widgets.dart';
import 'package:shell/models/models.dart';

/// Marks [child] as the place to drop files for [target], so a drag over
/// it finds it.
class DropTargetRegion extends StatelessWidget {
  const DropTargetRegion({
    super.key,
    required this.target,
    required this.child,
  });

  final FilesDropTarget target;
  final Widget child;

  @override
  Widget build(BuildContext context) => MetaData(
    metaData: target,
    behavior: .translucent,
    child: child,
  );
}
