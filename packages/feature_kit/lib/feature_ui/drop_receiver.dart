import 'package:flutter/widgets.dart';

/// A feature's own place to drop things on, such as the shelf: files, text
/// and links dragged from other apps, or from Ferret itself, land here
/// instead of going to a device. Tag its widget with [DropReceiverRegion].
abstract interface class DropReceiver {
  /// A drag is over it, or left it: show that it would take the drop.
  void hover({required bool over});

  /// Files dropped on it, by their paths. Some sit in a temporary folder
  /// the system may empty, such as promised files: copy what you keep.
  Future<bool> takeFiles(List<String> paths);

  /// Text, or a web link when [isLink], dropped on it.
  Future<bool> takeText(String text, {required bool isLink});
}

/// Marks [child] as where things dropped go to [receiver].
class DropReceiverRegion extends StatelessWidget {
  const DropReceiverRegion({
    super.key,
    required this.receiver,
    required this.child,
  });

  final DropReceiver receiver;
  final Widget child;

  @override
  Widget build(BuildContext context) => MetaData(
    metaData: receiver,
    behavior: .translucent,
    child: child,
  );
}
