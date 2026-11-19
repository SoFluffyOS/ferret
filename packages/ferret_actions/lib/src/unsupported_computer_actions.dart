import 'package:ferret_actions/src/computer_action.dart';
import 'package:ferret_actions/src/computer_actions.dart';

/// Phones and anything else: nothing to do from here.
class UnsupportedComputerActions implements ComputerActions {
  const UnsupportedComputerActions();

  @override
  Set<ComputerAction> get supported => const {};

  @override
  Future<bool> run(ComputerAction action) async => false;
}
