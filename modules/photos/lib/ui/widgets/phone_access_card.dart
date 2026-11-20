import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_photos/ferret_photos.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Photos in a phone's Settings: what the system lets Ferret see, the way
/// to change it, and which computers see the photos.
class PhoneAccessCard extends StatelessWidget {
  const PhoneAccessCard({
    super.key,
    required this.access,
    required this.sharedWith,
    required this.onAllow,
    required this.onOpenSettings,
    this.switches = const [],
  });

  final PhotoLibraryAccess access;

  /// Names of the computers that see the photos.
  final List<String> sharedWith;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;

  /// Switches for single computers, such as the one that just asked.
  final List<Widget> switches;

  @override
  Widget build(BuildContext context) {
    final l10n = context.photosL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final line = switch (access) {
      .full => l10n.settingsFull,
      .limited => l10n.settingsLimited,
      .denied => l10n.settingsDenied,
      .notAsked => l10n.settingsNotAsked,
      .unavailable || .unsupported => l10n.settingsUnavailable,
    };
    final action = switch (access) {
      .limited => (l10n.allowMore, onAllow),
      .notAsked => (l10n.allowPhotos, onAllow),
      .denied => (l10n.openSettings, onOpenSettings),
      _ => null,
    };
    final sharing = switch (sharedWith) {
      [] => l10n.settingsSharingNone,
      final names => l10n.settingsSharing(
        ListText.join(names, localeName: l10n.localeName),
      ),
    };

    return GroupedCard(
      children: [
        GroupedCell(
          child: Column(
            crossAxisAlignment: .start,
            mainAxisSize: .min,
            children: [
              Text(line, style: typography.base2.copyWith(color: palette.text)),
              Spacing.v4,
              Text(
                sharing,
                style: typography.base2.copyWith(color: palette.mutedText),
              ),
            ],
          ),
        ),
        ...switches,
        if (action case (final label, final onPressed))
          GroupedCell(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GhostButton(
                mainAxisSize: .min,
                label: label,
                onPressed: onPressed,
              ),
            ),
          ),
        GroupedCell(
          child: Text(
            l10n.settingsPerDevice,
            style: typography.base2.copyWith(color: palette.mutedText),
          ),
        ),
      ],
    );
  }
}
