import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:shell/l10n/l10n.dart';
import 'package:shell/services/menubar_icon_inputs.dart';

/// What the menubar icon says when the pointer rests on it: the state in
/// plain words, naming the device where it is known.
class MenubarTooltips {
  const MenubarTooltips(this._l10n);

  final ShellLocalizations _l10n;

  String of(MenubarIconState state, MenubarIconInputs inputs) =>
      switch (state) {
        .normal => _connected(inputs),
        .alone => _l10n.menubarTipAlone,
        .dragOver => _l10n.appName,
        .working => _working(inputs),
        .done => _l10n.menubarTipDone,
        .needsYou => _needsYou(inputs),
        .paused => _l10n.menubarTipPaused,
      };

  String _connected(MenubarIconInputs inputs) {
    if (inputs.connectedName.isEmpty) {
      return _l10n.menubarTipConnected(inputs.connectedCount);
    }

    return _l10n.menubarTipConnectedTo(inputs.connectedName);
  }

  String _working(MenubarIconInputs inputs) {
    final name = inputs.peerName;
    if (name.isEmpty) {
      return switch (inputs.isSending) {
        true => _l10n.menubarTipSending,
        false => _l10n.menubarTipReceiving,
      };
    }

    return switch (inputs.isSending) {
      true => _l10n.menubarTipSendingTo(name),
      false => _l10n.menubarTipReceivingFrom(name),
    };
  }

  String _needsYou(MenubarIconInputs inputs) {
    final name = inputs.waitingName;
    if (inputs.waitingCount > 1 || name.isEmpty) {
      return _l10n.menubarTipWaiting(inputs.waitingCount);
    }

    return switch (inputs.isPairingWaiting) {
      true => _l10n.menubarTipPair(name),
      false => _l10n.menubarTipRequest(name),
    };
  }
}
