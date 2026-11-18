import 'package:protocol/protocol.dart';

/// The other device in a handoff, as people see it.
class HandoffPeer {
  const HandoffPeer({
    required this.id,
    required this.name,
    this.platform = .PLATFORM_UNSPECIFIED,
    this.formFactor = .FORM_FACTOR_UNSPECIFIED,
  });

  factory HandoffPeer.fromInfo(String id, DeviceInfo? info) => HandoffPeer(
    id: id,
    name: switch (info?.name) {
      final name? when name.isNotEmpty => name,
      _ => id,
    },
    platform: info?.platform ?? .PLATFORM_UNSPECIFIED,
    formFactor: info?.formFactor ?? .FORM_FACTOR_UNSPECIFIED,
  );

  final String id;
  final String name;
  final Platform platform;
  final FormFactor formFactor;
}
