import 'dart:async';

import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:shell/services/menubar_icon_inputs.dart';

/// Picks the one state the menubar icon shows. Something waiting for the
/// person wins, then another device seeing or controlling this one (the
/// dot stays as long as it does), then a running transfer, then paused; the check shows for
/// [doneHold] after the last running transfer went through, and otherwise
/// the icon says whether any device is connected.
///
/// A drag over the icon is the Mac's own business and never comes from here.
class MenubarIconResolver {
  MenubarIconResolver({
    required void Function() onHoldEnded,
    this.doneHold = const Duration(milliseconds: 1500),
    Timer Function(Duration hold, void Function() onEnded) createTimer =
        Timer.new,
  }) : _onHoldEnded = onHoldEnded,
       _createTimer = createTimer;

  /// How long the check stays.
  final Duration doneHold;

  final void Function() _onHoldEnded;
  final Timer Function(Duration hold, void Function() onEnded) _createTimer;
  Timer? _doneTimer;
  int _finishedCount = 0;

  /// The state for [inputs]. Call it on every change; [onHoldEnded] fires
  /// when the check's time is up, to ask again.
  MenubarIconState resolve(MenubarIconInputs inputs) {
    final finishedMore = inputs.finishedCount > _finishedCount;
    _finishedCount = inputs.finishedCount;
    // A transfer that went through while another still runs gets no check:
    // the ring stays, and how the last one ends decides.
    if (finishedMore && inputs.progress == null) {
      _holdDone();
    }

    if (inputs.waitingCount > 0 || inputs.isWatched) {
      return .needsYou;
    }

    if (inputs.progress != null) {
      return .working;
    }

    if (inputs.isPaused) {
      return .paused;
    }

    if (_doneTimer != null) {
      return .done;
    }

    if (inputs.connectedCount > 0) {
      return .normal;
    }

    return .alone;
  }

  void dispose() {
    _doneTimer?.cancel();
    _doneTimer = null;
  }

  void _holdDone() {
    _doneTimer?.cancel();
    _doneTimer = _createTimer(doneHold, () {
      _doneTimer = null;
      _onHoldEnded();
    });
  }
}
