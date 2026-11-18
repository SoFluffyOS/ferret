import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/services/services.dart';
import 'package:shell/ui/onboarding/onboarding_page.dart';
import 'package:shell/ui/pages/home_page.dart';

/// Shows onboarding on the first run, the home screen after that.
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool? _onboarded;

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;
    final hasDevices = context.select<EngineHost, bool>(
      (host) => host.devices.isNotEmpty,
    );
    final onboarded =
        _onboarded ??
        (hasDevices ||
            (engine.settings.get<bool>(OnboardingPage.doneKey) ?? false));

    if (onboarded) {
      return const HomePage();
    }

    return OnboardingPage(onDone: () => setState(() => _onboarded = true));
  }
}
