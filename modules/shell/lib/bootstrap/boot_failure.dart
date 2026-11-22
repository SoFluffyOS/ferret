import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shell/app/ferret_theme.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Ferret couldn't get ready: says so plainly, with Try again, instead of
/// leaving the launch screen up for good. A small app of its own, since
/// the real one never came.
class BootFailure extends StatelessWidget {
  const BootFailure({
    super.key,
    required this.onRetry,
    required this.isRetrying,
  });

  final VoidCallback onRetry;

  /// Trying again right now: the button waits.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFE8833A),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        ShellLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: ShellLocalizations.supportedLocales,
      locale: AppLocale.chosen.value,
      builder: (context, _) => FerretTheme(
        child: _BootFailurePage(onRetry: onRetry, isRetrying: isRetrying),
      ),
    );
  }
}

class _BootFailurePage extends StatelessWidget {
  const _BootFailurePage({required this.onRetry, required this.isRetrying});

  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.shellL10n;

    return ColoredBox(
      color: palette.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Spacing.d24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PaneWidths.narrowContent,
              ),
              child: Column(
                mainAxisSize: .min,
                children: [
                  FerretLogo(size: Spacing.d64),
                  Spacing.v16,
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.bootFailedTitle,
                      textAlign: .center,
                      style: typography.title2.copyWith(color: palette.text),
                    ),
                  ),
                  Spacing.v8,
                  Text(
                    l10n.bootFailedBody(ThisComputer.here),
                    textAlign: .center,
                    style: typography.base1.copyWith(
                      color: palette.mutedText,
                    ),
                  ),
                  Spacing.v24,
                  Button(
                    variant: .primary,
                    label: l10n.bootRetry,
                    enable: !isRetrying,
                    mainAxisSize: .min,
                    titleExpand: .shrink,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
