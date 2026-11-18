/// The two Apple services an iPhone offers a bonded Bluetooth LE device.
enum AppleService {
  /// Apple Notification Center Service.
  ancs('7905F431-B5CE-4E99-A40F-4B1E122D00D0'),

  /// Apple Media Service.
  ams('89D3502B-0F36-433A-8EF4-C502AD55F8DC');

  const AppleService(this.uuid);

  /// Upper case, as Apple writes it.
  final String uuid;
}

/// The characteristics of ANCS and AMS, from Apple's specifications.
enum AppleCharacteristic {
  /// ANCS: tells about each notification that arrives, changes or goes.
  notificationSource(.ancs, '9FBF120D-6301-42D9-8C58-25E699A21DBD'),

  /// ANCS: takes commands (get attributes, perform an action).
  controlPoint(.ancs, '69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9'),

  /// ANCS: answers the commands written to [controlPoint].
  dataSource(.ancs, '22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB'),

  /// AMS: takes play, pause and so on; notifies which commands work now.
  remoteCommand(.ams, '9B3C81D8-57B1-4A8A-B8DF-0E56F7CA51C2'),

  /// AMS: write what to follow, then get the player, queue and track values.
  entityUpdate(.ams, '2F7CABCE-808D-411F-9A0C-BB92BA96C102'),

  /// AMS: reads a value that was cut short in [entityUpdate].
  entityAttribute(.ams, 'C6B2F38C-23AB-46D8-A6AB-A3A870BBD5D7');

  const AppleCharacteristic(this.service, this.uuid);

  final AppleService service;

  /// Upper case, as Apple writes it.
  final String uuid;

  static AppleCharacteristic? fromUuid(String uuid) {
    final wanted = uuid.toUpperCase();
    for (final characteristic in values) {
      if (characteristic.uuid == wanted) {
        return characteristic;
      }
    }

    return null;
  }
}
