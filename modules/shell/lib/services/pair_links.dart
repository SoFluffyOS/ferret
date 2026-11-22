import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';

/// A computer's pairing QR code scanned with the phone's own camera opens
/// Ferret with a `ferret://pair` link. This hands each such link to [open],
/// the one Ferret started with too, and one that came while Ferret was
/// still getting ready, each once.
class PairLinks {
  PairLinks({
    required Stream<Uri> links,
    required Future<Uri?> Function() initial,
    Future<Uri?> Function()? latest,
    required void Function(String link) open,
    DateTime Function()? now,
  }) : _links = links,
       _initial = initial,
       _latest = latest ?? _none,
       _open = open,
       _now = now ?? DateTime.now;

  /// The phone's links, opened over whatever [navigatorKey] shows.
  factory PairLinks.forApp(
    GlobalKey<NavigatorState> navigatorKey,
    Widget Function(String link) page,
  ) {
    final appLinks = AppLinks();
    return PairLinks(
      links: appLinks.uriLinkStream,
      initial: appLinks.getInitialLink,
      latest: appLinks.getLatestLink,
      open: (link) => unawaited(_push(navigatorKey, page(link))),
    );
  }

  final Stream<Uri> _links;
  final Future<Uri?> Function() _initial;
  final Future<Uri?> Function() _latest;
  final void Function(String link) _open;
  final DateTime Function() _now;
  final Map<String, DateTime> _opened = {};
  StreamSubscription<Uri>? _subscription;

  /// The plugin sends the link Ferret started with down the stream as well
  /// as from [_initial]; the same link this close together is that echo.
  static const _sameLink = Duration(seconds: 3);

  /// How long a link Ferret started with waits for the first screen.
  static const _navigatorPatience = Duration(seconds: 5);

  /// Listens, then catches up: the link Ferret started with, and the last
  /// one, which the plugin keeps but doesn't stream when it came before
  /// anyone listened.
  Future<void> start() async {
    _subscription = _links.listen(_handle);
    for (final read in [_initial, _latest]) {
      try {
        if (await read() case final link?) {
          _handle(link);
        }
      } on Object {
        // No link to catch up on, or the platform can't tell.
      }
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

    final link = uri.toString();
    final now = _now();
    if (_opened[link] case final openedAt?
        when now.difference(openedAt) < _sameLink) {
      return;
    }

    _opened[link] = now;
    _open(link);
  }

  static Future<Uri?> _none() async => null;

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
