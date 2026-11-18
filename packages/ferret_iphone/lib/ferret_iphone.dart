/// Talks to an iPhone from a desktop over the Bluetooth LE services every
/// iPhone has: ANCS for notifications and their actions, AMS for what it
/// plays. No app is needed on the iPhone; it only has to be paired.
library;

export 'package:ferret_iphone/src/ams/ams.dart';
export 'package:ferret_iphone/src/ancs/ancs.dart';
export 'package:ferret_iphone/src/transport/transport.dart';
