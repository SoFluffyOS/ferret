import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:protocol/protocol.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';
import 'package:wake/l10n/l10n.dart';
import 'package:wake/ui/widgets/widgets.dart';

/// How to turn on Wake-on-LAN: what the computer said about its cards, what
/// works, and the steps for each system, the computer's own first.
class WakeHelpPage extends StatelessWidget {
  const WakeHelpPage({
    super.key,
    required this.platform,
    this.deviceName,
    this.told,
    this.fromIphone = false,
  });

  /// The system of the computer to wake.
  final Platform platform;

  /// The computer's name, or null for this computer.
  final String? deviceName;

  /// What it said about its cards, or null when it said nothing.
  final List<WakeInterface>? told;

  /// Opened on an iPhone, which can't send the packet by itself.
  final bool fromIphone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.wakeL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final cards = told ?? const <WakeInterface>[];
    final systems = [
      (
        platform: Platform.PLATFORM_MACOS,
        title: l10n.helpMacTitle,
        body: l10n.helpMac,
      ),
      (
        platform: Platform.PLATFORM_WINDOWS,
        title: l10n.helpWindowsTitle,
        body: l10n.helpWindows,
      ),
      (
        platform: Platform.PLATFORM_LINUX,
        title: l10n.helpLinuxTitle,
        body: l10n.helpLinux,
      ),
    ];
    final ordered = [
      ...systems.where((system) => system.platform == platform),
      ...systems.where((system) => system.platform != platform),
    ];
    final needsFirmware = platform != .PLATFORM_MACOS;

    return FerretPage(
      title: l10n.helpTitle,
      children: [
        Text(
          l10n.helpIntro,
          style: typography.body2.copyWith(color: palette.text),
        ),
        Spacing.v12,
        if (fromIphone)
          HelpSection(title: l10n.helpIphoneTitle, body: l10n.helpIphone),
        SectionTitle(switch (deviceName) {
          final name? => l10n.helpToldTitle(name),
          null => l10n.helpThisComputer,
        }),
        GroupedCard(
          children: [
            if (cards.isEmpty)
              GroupedCell(
                child: Text(
                  l10n.cardNone,
                  style: typography.base2.copyWith(color: palette.mutedText),
                ),
              ),
            for (final card in cards)
              GroupedCell(
                child: CardLine(link: card.link, setting: card.setting),
              ),
          ],
        ),
        Spacing.v12,
        HelpSection(title: l10n.helpBestTitle, body: l10n.helpBest),
        for (final (index, system) in ordered.indexed) ...[
          HelpSection(title: system.title, body: system.body),
          if (index == 0 && needsFirmware)
            HelpSection(
              title: l10n.helpFirmwareTitle,
              body: l10n.helpFirmware,
            ),
        ],
        if (!needsFirmware)
          HelpSection(title: l10n.helpFirmwareTitle, body: l10n.helpFirmware),
        if (!fromIphone)
          HelpSection(title: l10n.helpIphoneTitle, body: l10n.helpIphone),
      ],
    );
  }
}
