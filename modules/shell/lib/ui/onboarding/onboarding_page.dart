import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shell/app/shell_scope.dart';
import 'package:shell/ui/onboarding/name_step.dart';
import 'package:shell/ui/onboarding/pair_step.dart';
import 'package:shell/ui/onboarding/ready_step.dart';
import 'package:shell/ui/onboarding/welcome_step.dart';

/// The first run: welcome, name this device, pair, ready. Each step is one
/// screen with one main button.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onDone});

  /// Called once the person finishes, so the app shows the home screen.
  final VoidCallback onDone;

  /// Settings key that marks the first run as done.
  static const doneKey = 'onboarding.done';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

enum _Step { welcome, name, pair, ready }

class _OnboardingPageState extends State<OnboardingPage> {
  static const _total = 4;

  _Step _step = .welcome;
  String? _pairedName;

  @override
  Widget build(BuildContext context) {
    final engine = ShellScope.of(context).featureContext.engine;

    return switch (_step) {
      .welcome => WelcomeStep(total: _total, onNext: () => _go(.name)),
      .name => NameStep(
        total: _total,
        initialName: engine.device.name,
        onNext: (name) {
          unawaited(engine.rename(name));
          _go(.pair);
        },
      ),
      .pair => PairStep(
        total: _total,
        engine: engine,
        onPaired: (name) {
          _pairedName = name;
          _go(.ready);
        },
        onLater: () => _go(.ready),
      ),
      .ready => ReadyStep(
        total: _total,
        pairedName: _pairedName,
        onFinish: _finish,
      ),
    };
  }

  void _go(_Step step) => setState(() => _step = step);

  Future<void> _finish() async {
    final engine = ShellScope.read(context).featureContext.engine;
    await engine.settings.set(OnboardingPage.doneKey, true);
    widget.onDone();
  }
}
