import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/app.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:shell/ui/pages/device_page.dart';
import 'package:shell/ui/pages/doctor_page.dart';
import 'package:shell/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One section of a device: its Overview, or the page a feature has for it.
/// A section that is gone (the feature stopped applying to the device)
/// falls back to the Overview, never to a blank page.
class DeviceSectionPage extends StatelessWidget {
  const DeviceSectionPage({
    super.key,
    required this.deviceId,
    required this.sectionId,
  });

  final String deviceId;
  final String sectionId;

  @override
  Widget build(BuildContext context) {
    if (sectionId == FeatureSection.overviewId) {
      return DevicePage(deviceId: deviceId);
    }

    final status = context.select<EngineHost, DeviceStatus?>(
      (host) => host.statusOf(deviceId),
    );
    if (status == null) {
      return DevicePage(deviceId: deviceId);
    }

    final scope = ShellScope.of(context);

    return FeatureChangesListener(
      features: scope.features,
      builder: (context) {
        final sections = DeviceSections.of(
          context,
          scope.features,
          scope.featureContext,
          status,
        );
        for (final section in sections) {
          if (section.id == sectionId) {
            return _Section(status: status, section: section);
          }
        }

        return DevicePage(deviceId: deviceId);
      },
    );
  }
}

/// A feature's page for a device. While the device is offline the page
/// stays, showing what it loaded last under a line that says so.
class _Section extends StatelessWidget {
  const _Section({required this.status, required this.section});

  final DeviceStatus status;
  final FeatureSection section;

  @override
  Widget build(BuildContext context) {
    final isOffline = !status.isConnected;
    final media = MediaQuery.of(context);

    return ColoredBox(
      color: context.palette.background,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          if (isOffline)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  Spacing.d12,
                  Spacing.d12,
                  Spacing.d12,
                  Spacing.d0,
                ),
                child: AdaptiveContent(
                  width: switch (section.fillsPane) {
                    true => .fill,
                    false => .page,
                  },
                  child: OfflineLine(
                    text: _offlineText(context),
                    fixLabel: context.shellL10n.doctorTitle,
                    onFix: () => Navigator.of(context).push(
                      ferretRoute<void>(
                        DoctorPage(deviceId: status.device.id),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: MediaQuery(
              // The line above already keeps clear of the top of the screen.
              data: switch (isOffline) {
                true => media.removePadding(removeTop: true),
                false => media,
              },
              child: KeyedSubtree(
                key: ValueKey(section.id),
                child: section.builder(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _offlineText(BuildContext context) {
    final l10n = context.shellL10n;
    final name = status.device.name;
    final lastSeen = status.device.lastSeen;
    if (lastSeen == null) {
      return l10n.sectionOfflineNoTime(name);
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final seen = lastSeen.toLocal();
    final now = DateTime.now();
    final isToday =
        seen.year == now.year && seen.month == now.month && seen.day == now.day;
    final time = switch (isToday) {
      true => DateFormat.jm(locale).format(seen),
      false => DateFormat.MMMd(locale).add_jm().format(seen),
    };

    return l10n.sectionOffline(name, time);
  }
}
