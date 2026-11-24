/// Where things live on ferret.sofluffy.io and around it.
abstract final class SiteLinks {
  static const origin = 'https://ferret.sofluffy.io';
  static const docs = '/docs';
  static const privacy = '/docs/privacy';
  static const pairing = '/docs/getting-started/pairing';
  static const iphoneLimits = '/docs/iphone/limits';
  static const github = 'https://github.com/SoFluffyOS/ferret';
  static const releases = 'https://github.com/SoFluffyOS/ferret/releases';

  /// Files of the newest release, by a name every release keeps.
  static const latest = '$releases/latest/download';
  static const installScript = '$origin/install.sh';
  static const license =
      'https://github.com/SoFluffyOS/ferret/blob/main/LICENSE';
  static const sponsor = 'https://github.com/sponsors/simonpham';
  static const lumide = 'https://lumide.dev';
  static const logo = '/images/logo.svg';
  static const socialImage = '$origin/images/social-landing.png';
  static const stylesheet = '/landing.css';
}
