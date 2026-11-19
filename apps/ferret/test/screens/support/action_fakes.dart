// ignore_for_file: depend_on_referenced_packages
import 'package:actions/actions.dart';
import 'package:ferret_actions/ferret_actions.dart';
import 'package:ferret_remote_input/ferret_remote_input.dart';

/// Never the real thing: a render must not put this Mac to sleep.
class NoComputer implements ComputerActions {
  const NoComputer();

  @override
  Set<ComputerAction> get supported => ComputerAction.values.toSet();

  @override
  Future<bool> run(ComputerAction action) async => true;
}

/// Starts nothing, and says every command worked.
class NoCommands implements CommandRunner {
  const NoCommands();

  @override
  Future<CommandOutcome> run(
    List<String> command, {
    Duration timeout = const Duration(seconds: 30),
  }) async => const CommandOutcome(exitCode: 0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Never locks this Mac: says it did.
class NoLocker implements ScreenLocker {
  const NoLocker();

  @override
  bool get isSupported => true;

  @override
  Future<bool> lock() async => true;
}

/// Nobody at the keyboard for ten minutes.
class AwayFromKeyboard implements InputIdle {
  const AwayFromKeyboard();

  @override
  Future<Duration?> idleTime() async => const Duration(minutes: 10);
}

/// Computer actions that can't touch the computer the tests run on. Whether
/// it offers actions follows the device it is given: computers do.
/// [lockMinute] shortens the wait before a phone that left locks it.
ActionsFeature safeActionsFeature({
  Duration lockMinute = const Duration(minutes: 1),
  Duration countdownLength = const Duration(seconds: 10),
}) => ActionsFeature(
  computer: const NoComputer(),
  runner: const NoCommands(),
  locker: const NoLocker(),
  idle: const AwayFromKeyboard(),
  lockMinute: lockMinute,
  countdownLength: countdownLength,
);
