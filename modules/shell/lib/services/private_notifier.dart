import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:shell/services/private_previews.dart';

/// Shows notices for every feature, covering private ones (see
/// [PrivateContent]) when their device's previews are off here, or while
/// the screen is locked or another account is in front ([isAtScreen]).
class PrivateNotifier implements LocalNotifier {
  PrivateNotifier(
    this._notifier, {
    required PrivatePreviews previews,
    required bool Function() isAtScreen,
    required String Function() coverBody,
  }) : _previews = previews,
       _isAtScreen = isAtScreen,
       _coverBody = coverBody;

  final LocalNotifier _notifier;
  final PrivatePreviews _previews;
  final bool Function() _isAtScreen;
  final String Function() _coverBody;

  /// Whether [notice] may show what it says right now.
  bool shows(LocalNotice notice) {
    final private = notice.private;
    if (private == null) {
      return true;
    }

    return _isAtScreen() && _previews.showsFrom(private.deviceId);
  }

  @override
  Future<void> show(LocalNotice notice) {
    if (shows(notice)) {
      return _notifier.show(notice);
    }

    return _notifier.show(notice.covered(_coverBody()));
  }

  @override
  Future<void> cancel(String id) => _notifier.cancel(id);

  @override
  Stream<NoticeResponse> get responses => _notifier.responses;
}
