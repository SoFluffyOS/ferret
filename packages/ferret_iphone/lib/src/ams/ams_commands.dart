import 'dart:typed_data';

import 'package:ferret_iphone/src/ams/ams_ids.dart';

/// Builds what is written to the AMS characteristics, and reads the list of
/// commands the iPhone accepts right now.
abstract final class AmsCommands {
  /// Written to Entity Update: follow [attributes] of [entity].
  static Uint8List subscribe(AmsEntity entity, List<int> attributes) =>
      Uint8List.fromList([entity.index, ...attributes]);

  /// Written to Entity Attribute before reading the full value from it.
  static Uint8List select(AmsEntity entity, int attribute) =>
      Uint8List.fromList([entity.index, attribute]);

  /// Written to Remote Command.
  static Uint8List remote(AmsCommand command) =>
      Uint8List.fromList([command.id]);

  /// A Remote Command notification: one byte per command that works now.
  static Set<AmsCommand> supported(Uint8List bytes) => {
    for (final id in bytes) ?AmsCommand.fromId(id),
  };
}
