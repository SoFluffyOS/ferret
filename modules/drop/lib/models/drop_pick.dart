import 'package:drop/models/drop_target.dart';

/// What the send picker chose: a device, and for a shared link, whether
/// it opens there instead of arriving as text.
class DropPick {
  const DropPick(this.target, {this.opens = false});

  final DropTarget target;
  final bool opens;
}
