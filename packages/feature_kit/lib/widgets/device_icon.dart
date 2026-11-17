import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:protocol/protocol.dart';

/// The icon for a device's kind, such as a phone or a laptop.
IconData deviceIconFor(FormFactor formFactor, Platform platform) =>
    switch (formFactor) {
      .FORM_FACTOR_PHONE => LucideIcons.smartphone,
      .FORM_FACTOR_TABLET => LucideIcons.tablet,
      .FORM_FACTOR_LAPTOP => LucideIcons.laptop,
      .FORM_FACTOR_DESKTOP => LucideIcons.monitor,
      .FORM_FACTOR_SERVER => LucideIcons.server,
      _ => switch (platform) {
        .PLATFORM_ANDROID || .PLATFORM_IOS => LucideIcons.smartphone,
        .PLATFORM_BROWSER => LucideIcons.globe,
        .PLATFORM_CLI => LucideIcons.terminal,
        _ => LucideIcons.computer,
      },
    };
