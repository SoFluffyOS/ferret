// ignore_for_file: depend_on_referenced_packages
import 'package:actions/actions.dart';
import 'package:ferret_actions/ferret_actions.dart';

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

/// Computer actions that can't touch the computer the tests run on. Whether
/// it offers actions follows the device it is given: computers do.
ActionsFeature safeActionsFeature() =>
    ActionsFeature(computer: const NoComputer(), runner: const NoCommands());
