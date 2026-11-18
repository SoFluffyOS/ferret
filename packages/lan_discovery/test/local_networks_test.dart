import 'dart:io';

import 'package:lan_discovery/lan_discovery.dart';
import 'package:test/test.dart';

void main() {
  test('knows which addresses are local', () {
    expect(LocalNetworks.contains(InternetAddress('10.0.0.5')), isTrue);
    expect(LocalNetworks.contains(InternetAddress('172.16.4.1')), isTrue);
    expect(LocalNetworks.contains(InternetAddress('172.32.0.1')), isFalse);
    expect(LocalNetworks.contains(InternetAddress('192.168.0.9')), isTrue);
    expect(LocalNetworks.contains(InternetAddress('169.254.3.3')), isTrue);
    expect(LocalNetworks.contains(InternetAddress('127.0.0.1')), isTrue);
    expect(LocalNetworks.contains(InternetAddress('1.1.1.1')), isFalse);
    expect(LocalNetworks.contains(InternetAddress('fd12::1')), isTrue);
    expect(LocalNetworks.contains(InternetAddress('2001:db8::1')), isFalse);
  });
}
