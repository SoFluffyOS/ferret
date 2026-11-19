import 'package:protocol/protocol.dart';

/// The other device in a handoff, as people see it.
class HandoffPeer {
  const HandoffPeer({
    required this.id,
    required this.name,
    this.platform = .PLATFORM_UNSPECIFIED,
    this.formFactor = .FORM_FACTOR_UNSPECIFIED,
  });

  /// [name] is what this device calls it, from `FeatureHost.displayNameOf`.
  factory HandoffPeer.fromInfo(
    String id,
    DeviceInfo? info, {
    required String name,
  }) => HandoffPeer(
    id: id,
    name: name,
    platform: info?.platform ?? .PLATFORM_UNSPECIFIED,
    formFactor: info?.formFactor ?? .FORM_FACTOR_UNSPECIFIED,
  );

  final String id;
  final String name;
  final Platform platform;
  final FormFactor formFactor;
}
