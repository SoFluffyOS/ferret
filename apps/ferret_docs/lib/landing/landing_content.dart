import 'package:ferret_docs/landing/feature_story.dart';
import 'package:ferret_docs/landing/site_links.dart';

/// The words on the landing page, in one place so they are easy to edit.
abstract final class LandingContent {
  static const title = 'Ferret: your phone and your computers, working as one';
  static const description =
      'Copy on your phone, paste on your laptop. Send files, answer calls, see '
      'your phone’s screen. Android, iPhone, Mac, Windows and Linux, on your '
      'Wi-Fi, with no account. Free and open source.';

  static const pitch = 'Your phone and your computers, working as one.';

  /// What the name stands for.
  static const acronym =
      'F.E.R.R.E.T. · Fast Encrypted Relay for Resuming Every Task';
  static const subPitch =
      'Copy on one, paste on the other. Send files, answer calls, see your '
      'phone’s screen. On the Wi-Fi you already have, with no account and no '
      'cloud.';

  static const platforms = <PlatformEntry>[
    (
      icon: 'android',
      name: 'Android',
      how: 'App with a quiet background service and a Quick Settings tile.',
      guide: '/docs/getting-started/android',
      download: '${SiteLinks.latest}/Ferret-android.apk',
      downloadLabel: 'Download .apk',
      command: null,
    ),
    (
      icon: 'apple',
      name: 'iPhone',
      how: 'Not in the first release yet. It builds from source today.',
      guide: '/docs/getting-started/iphone',
      download: null,
      downloadLabel: null,
      command: null,
    ),
    (
      icon: 'apple',
      name: 'Mac',
      how:
          'Menubar app with a popover and a full window. macOS 12 or later, signed and notarized.',
      guide: '/docs/getting-started/mac',
      download: '${SiteLinks.latest}/Ferret-mac.dmg',
      downloadLabel: 'Download .dmg',
      command: null,
    ),
    (
      icon: 'windows',
      name: 'Windows',
      how: 'Window and tray icon. Installs just for you, no admin.',
      guide: '/docs/getting-started/windows',
      download: '${SiteLinks.latest}/Ferret-windows-x64-setup.exe',
      downloadLabel: 'Download .exe',
      command: null,
    ),
    (
      icon: 'linux',
      name: 'Linux',
      how:
          'Window and tray icon. One line installs the AppImage, or get the Flatpak or .deb.',
      guide: '/docs/getting-started/linux',
      download: null,
      downloadLabel: null,
      command: 'curl -fsSL ferret.sofluffy.io/install.sh | sh',
    ),
  ];

  static const stories = <FeatureStory>[
    FeatureStory(
      id: 'clipboard',
      icon: 'clipboard',
      title: 'Copy here, paste there',
      lead:
          'Copy on your phone, paste on your laptop. Text, links and images. '
          'No emailing yourself.',
      points: [
        '**Recent clips** keeps the last 20 things you copied, on any device. One click copies one again.',
        'Password-manager items stay put. Private items never show up.',
      ],
      shot: 'recent-clips',
      frame: ShotFrame.popover,
      alt:
          'Recent clips in Ferret: three things copied on a Pixel 7, each with '
          'a Copy button',
      width: 760,
      height: 640,
      docs: '/docs/features/clipboard',
      docsLabel: 'How the clipboard works',
    ),
    FeatureStory(
      id: 'files',
      icon: 'folder-up',
      title: 'Files and folders, right where you want them',
      lead:
          'Drop a file on a device and it’s there. Send a whole folder and it '
          'arrives as a folder.',
      points: [
        'Checked with SHA-256, picks up again after a dropped connection, never overwrites.',
        '**Share → Ferret** on Mac and iPhone, **Send with Ferret** on Windows and Linux.',
        'Works with **LocalSend**, and Android phones can send with **Quick Share** with nothing installed.',
      ],
      shot: 'popover-home',
      frame: ShotFrame.popover,
      alt:
          'The Ferret menubar popover on a Mac: a file waiting, a call ringing '
          'and your devices',
      width: 760,
      height: 1120,
      docs: '/docs/features/drop',
      docsLabel: 'Send files and folders',
    ),
    FeatureStory(
      id: 'phone',
      icon: 'bell',
      title: 'Your phone, on your computer',
      lead:
          'Your Android phone rings in the other room. Answer it from your '
          'desk.',
      points: [
        'Notifications with **Reply** and **Dismiss**, synced both ways.',
        'Read and reply to your texts.',
        'See who’s calling, then answer, decline or silence. Your music pauses while you talk.',
        'One-time codes stay on the phone as **Code hidden** unless you say otherwise.',
      ],
      shot: 'calls',
      frame: ShotFrame.window,
      alt:
          'The Calls page for a Pixel 9 in the Ferret window: a call field and '
          'recent calls',
      width: 1400,
      height: 940,
      docs: '/docs/features/notifications',
      docsLabel: 'Notifications, texts and calls',
    ),
    FeatureStory(
      id: 'screen',
      icon: 'monitor-smartphone',
      title: 'Your phone’s screen, in a window',
      lead:
          '**Show screen** puts your Android phone on your computer, over '
          'Wi-Fi. Its sound comes along too.',
      points: [
        'Click, scroll and type on it: over Wi-Fi once the phone says yes, or over a cable with no Ferret on the phone.',
        'iPhone and iPad through AirPlay.',
        'A full-size screenshot in one click.',
      ],
      shot: 'screen-mirroring',
      frame: ShotFrame.window,
      alt:
          'A phone’s screen in its own window, with Back, Home, Rotate, '
          'Screenshot and Stop next to it',
      width: 1000,
      height: 1400,
      docs: '/docs/features/mirroring',
      docsLabel: 'Show your phone’s screen',
    ),
    FeatureStory(
      id: 'photos',
      icon: 'images',
      title: 'Phone photos, no cable',
      lead:
          'Browse your phone’s recent photos and screenshots from the '
          'computer, and save the ones you want.',
      points: [
        'New screenshots can land on the computer by themselves.',
        '**Take a photo**: press a key on the computer, shoot on the phone, and it’s on your clipboard.',
      ],
      shot: 'phone-photos',
      frame: ShotFrame.window,
      alt: 'A phone’s recent photos in a grid in the Ferret window',
      width: 1400,
      height: 1008,
      docs: '/docs/features/photos',
      docsLabel: 'Photos and the camera',
    ),
    FeatureStory(
      id: 'control',
      icon: 'locate-fixed',
      title: 'Find, wake and control',
      lead: 'Lost your phone in the couch? **Ring** it, even on silent.',
      points: [
        '**Wake** a sleeping computer with Wake-on-LAN.',
        'Your phone as a **touchpad and keyboard**, or a **presentation clicker**.',
        '**Sleep, restart, lock** or run your own commands on a computer. It asks first, once.',
        '**Lock when your phone leaves**: walk away with your Android phone and the computer locks.',
      ],
      shot: 'presentation',
      frame: ShotFrame.phone,
      alt:
          'A phone used as a presentation clicker: a big Next button, Previous '
          'and Black screen',
      width: 780,
      height: 1688,
      docs: '/docs/features/find',
      docsLabel: 'Find, wake and control',
    ),
  ];

  static const extras = <FeatureExtra>[
    (
      icon: 'arrow-right-left',
      title: 'Continue where you left off',
      body:
          'Send a page to another device with **Continue on…**, or from the '
          'browser extension. Pick up a song at the same second.',
      docs: '/docs/features/handoff',
    ),
    (
      icon: 'battery-medium',
      title: 'Every battery at a glance',
      body: 'See each device’s battery, and hear about it once when it’s low.',
      docs: '/docs/getting-started/settings',
    ),
    (
      icon: 'terminal',
      title: 'Scripts and shortcuts',
      body:
          '`ferret-cli watch --json`, hooks, a **Tasker** plugin and '
          '**Shortcuts** actions on iPhone.',
      docs: '/docs/features/scripting',
    ),
    (
      icon: 'stethoscope',
      title: 'Fix connection',
      body:
          'Devices won’t see each other? Ferret tells you why in plain words, '
          'with a button to fix it.',
      docs: '/docs/features/connection-doctor',
    ),
  ];

  static const privacyPoints = [
    'Your devices talk **directly to each other** on your network. Nothing goes through a server.',
    'Every connection is **end-to-end encrypted** with Noise.',
    'Only devices you **paired** can connect. Strangers on the same Wi-Fi can ask to pair, and that’s all.',
    '**No account, no analytics, no crash reporting, no ads.** Ferret never logs what you copy, send or read.',
  ];

  static const faq = <FaqEntry>[
    (
      question: 'Why a ferret?',
      answer:
          'Ferrets carry things off and stash them somewhere else. Your keys, '
          'a sock, the TV remote. That’s Ferret’s whole job, minus the '
          'stealing: it carries your clipboard, files and calls from one '
          'device to the next. And the name spells F.E.R.R.E.T.: Fast '
          'Encrypted Relay for Resuming Every Task.',
      link: null,
    ),
    (
      question: 'Is it really free?',
      answer:
          'Yes. No paid tier, no ads, no account. If Ferret saves you time, '
          'you can sponsor me on GitHub.',
      link: SiteLinks.sponsor,
    ),
    (
      question: 'Do my devices need to be on the same Wi-Fi?',
      answer:
          'Yes, the same local network. Your phone’s hotspot works too. Away '
          'from home, Ferret can use your own VPN, such as Tailscale. There '
          'is never a Ferret server in between.',
      link: '/docs/features/away-from-home',
    ),
    (
      question: 'How is it different from Apple’s Continuity?',
      answer:
          'Continuity is great when every device is Apple. Ferret does the '
          'same kind of thing across any mix, Android, Windows and Linux '
          'included.',
      link: null,
    ),
    (
      question: 'And Phone Link on Windows?',
      answer:
          'Phone Link wants a Microsoft account and only runs on Windows. '
          'Ferret needs no account and runs on Mac and Linux too.',
      link: null,
    ),
    (
      question: 'What about Quick Share, LocalSend or KDE Connect?',
      answer:
          'Quick Share and LocalSend are great for files, and Ferret talks to '
          'both. KDE Connect is the closest cousin, and a great project. '
          'Ferret is its own take, built to feel at home on every platform, '
          'with phone screen mirroring built in.',
      link: '/docs/interop/localsend',
    ),
    (
      question: 'Does it work on iPhone?',
      answer:
          'Yes, with limits. iOS pauses apps you leave, so Ferret syncs while '
          'it’s open, and the app can’t forward texts or calls. A computer '
          'can still show the iPhone’s notifications and media over '
          'Bluetooth.',
      link: SiteLinks.iphoneLimits,
    ),
    (
      question: 'Do I need root on Android?',
      answer:
          'No. Everything works without it. Shizuku or root only add extras, '
          'like sending your clipboard without a tap.',
      link: '/docs/android-modes/standard',
    ),
    (
      question: 'Where do I get it?',
      answer:
          'Right here, under Get Ferret: Mac, Windows, Linux and Android, '
          'always the newest release from GitHub. iPhone comes later; it '
          'builds from source today.',
      link: '#download',
    ),
  ];
}
