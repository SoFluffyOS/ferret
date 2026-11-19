import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// A computer's pairing QR code scanned with the phone's own camera opens
/// Ferret with a `ferret://pair` link. This hands each such link to [open],
/// the one Ferret started with too.
class PairLinks {
  PairLinks({
    required Stream<Uri> links,
    required Future<Uri?> Function() initial,
    required void Function(String link) open,
  }) : _links = links,
       _initial = initial,
       _open = open;

  /// The phone's links, opened over whatever [navigatorKey] shows.
  factory PairLinks.forApp(
    GlobalKey<NavigatorState> navigatorKey,
    Widget Function(String link) page,
  ) {
    final appLinks = AppLinks();
    return PairLinks(
      links: appLinks.uriLinkStream,
      initial: appLinks.getInitialLink,
      open: (link) => unawaited(_push(navigatorKey, page(link))),
    );
  }

  final Stream<Uri> _links;
  final Future<Uri?> Function() _initial;
  final void Function(String link) _open;
  StreamSubscription<Uri>? _subscription;

  /// How long a link Ferret started with waits for the first screen.
  static const _navigatorPatience = Duration(seconds: 5);

  Future<void> start() async {
    _subscription = _links.listen(_handle);
    try {
      final first = await _initial();
      if (first != null) {
        _handle(first);
      }
    } on Object {
      // No link to start with, or the platform can't tell.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handle(Uri uri) {
    if (!isPairLink(uri)) {
      return;
    }

    _open(uri.toString());
  }

  static bool isPairLink(Uri uri) =>
      uri.scheme == PairingCodes.scheme && uri.host == 'pair';

  static Future<void> _push(
    GlobalKey<NavigatorState> navigatorKey,
    Widget page,
  ) async {
    final deadline = DateTime.now().add(_navigatorPatience);
    while (navigatorKey.currentState == null &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    await navigatorKey.currentState?.push(ferretRoute<void>(page));
  }
}
