// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'wake_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class WakeLocalizationsEn extends WakeLocalizations {
  WakeLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Wake-on-LAN';

  @override
  String get wake => 'Wake';

  @override
  String get tryAgain => 'Try again';

  @override
  String get wakingButton => 'Waking…';

  @override
  String waking(String name) {
    return 'Waking $name… (up to a minute)';
  }

  @override
  String get didntWake => 'Didn\'t wake';

  @override
  String get couldntSend => 'Couldn\'t send the wake signal';

  @override
  String get howToTurnOn => 'How to turn on Wake-on-LAN';

  @override
  String get healthReady => 'Can wake it from sleep';

  @override
  String get healthWiredUnknown => 'Can try to wake it over its cable';

  @override
  String healthWiredOff(String name) {
    return 'Wake-on-LAN is off on $name';
  }

  @override
  String get healthWifiOnly => 'Wi-Fi only: it may not wake';

  @override
  String healthHelp(String name) {
    return 'On $name: Ferret → Settings → Control → Wake-on-LAN shows what to turn on.';
  }

  @override
  String get helpTitle => 'Wake-on-LAN';

  @override
  String get helpIntro =>
      'Wake-on-LAN starts a sleeping computer when another device sends it a “magic packet” over the network. Ferret sends one when you tap Wake. The computer has to allow it first, once.';

  @override
  String helpToldTitle(String name) {
    return 'What $name told Ferret';
  }

  @override
  String get helpThisComputer => 'This computer';

  @override
  String get cardWiredOn => 'Cable · Wake-on-LAN is on';

  @override
  String get cardWiredOff => 'Cable · Wake-on-LAN is off';

  @override
  String get cardWiredUnknown =>
      'Cable · can\'t tell whether Wake-on-LAN is on';

  @override
  String get cardWifi => 'Wi-Fi · few computers wake over Wi-Fi';

  @override
  String get cardNone =>
      'No network card to wake it by yet. Open Ferret on it once.';

  @override
  String get helpBestTitle => 'What works';

  @override
  String get helpBest =>
      'A cable to the router, asleep rather than shut down, and another of your devices on the same network. Over Wi-Fi most computers don\'t wake at all: a cable makes it reliable.';

  @override
  String get helpMacTitle => 'Mac';

  @override
  String get helpMac =>
      'System Settings → Battery → Options → Wake for network access (on a desktop Mac: System Settings → Energy). A Mac on Wi-Fi wakes only through a Bonjour Sleep Proxy, such as an Apple TV or HomePod on the same network.';

  @override
  String get helpWindowsTitle => 'Windows';

  @override
  String get helpWindows =>
      '1. Device Manager → Network adapters → your Ethernet card → Properties.\n2. Power Management: turn on “Allow this device to wake the computer” and “Only allow a magic packet to wake the computer”.\n3. Advanced: set “Wake on Magic Packet” to Enabled.\n4. To wake it from shut down, turn off Fast startup: Control Panel → Power Options → Choose what the power buttons do.';

  @override
  String get helpLinuxTitle => 'Linux';

  @override
  String get helpLinux =>
      'Turn it on for the card: sudo ethtool -s enp3s0 wol g (use your card\'s name from “ip link”).\nKeep it after a restart: nmcli connection modify \"Wired connection 1\" 802-3-ethernet.wake-on-lan magic.';

  @override
  String get helpFirmwareTitle => 'BIOS or UEFI (Windows and Linux PCs)';

  @override
  String get helpFirmware =>
      'Press F2, Del or F12 while the PC starts. Turn on “Wake on LAN”, “Power On by PCI-E” or a setting like it, and turn off “ErP” or “Deep Sleep”, which cut power to the network card.';

  @override
  String get helpIphoneTitle => 'From an iPhone';

  @override
  String get helpIphone =>
      'iOS doesn\'t let apps broadcast on the network, so an iPhone can\'t send the magic packet by itself. Ferret asks another of your devices that is on, such as a Mac, a PC or ferret-cli on a home server, to send it for you.';

  @override
  String get settingsShare => 'Let my devices wake this computer';

  @override
  String get settingsShareBody =>
      'Tells your paired devices, and only them, this computer\'s network card address (MAC), so they can wake it.';

  @override
  String get settingsRelay => 'Wake computers for my phones';

  @override
  String get settingsRelayBody =>
      'When one of your phones asks, this computer sends the wake signal to another of your computers on this network.';

  @override
  String get settingsReady => 'Ready';

  @override
  String get settingsNotReady => 'Off';

  @override
  String get settingsWifiOnly => 'Wi-Fi only';
}
