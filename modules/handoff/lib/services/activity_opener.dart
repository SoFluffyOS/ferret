import 'package:handoff/models/models.dart';
import 'package:protocol/handoff.dart';

/// Opens an activity on this device.
abstract interface class ActivityOpener {
  Future<OpenResult> open(Activity activity);
}
