import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/ui/onboarding/onboarding_page.dart';
import 'package:shell/ui/pages/home_page.dart';

/// Shows onboarding on the first run, the home screen after that.
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  late bool _onboarded;

  @override
  void initState() {
    super.initState();
    final scope = ShellScope.read(context);
    final engine = scope.featureContext.engine;
    final alreadyDone =
        engine.settings.get<bool>(OnboardingPage.doneKey) ?? false;

    // Decided once: pairing during onboarding must still reach the last step.
    _onboarded = alreadyDone || engine.trustStore.devices.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded) {
      return const HomePage();
    }

    return OnboardingPage(onDone: () => setState(() => _onboarded = true));
  }
}
