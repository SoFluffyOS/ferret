/// One event of `ferret-cli watch` in words, for people rather than
/// scripts: `09:30:12  Pixel 7 connected`.
abstract final class WatchLine {
  static String of(Map<String, Object?> event) {
    final device = switch (event['device']) {
      {'name': final String name} => name,
      _ => '',
    };
    final time = _timeOf(event['at']);
    final what = _describe('${event['type']}', device, event);

    return '$time  $what';
  }

  static String _describe(
    String type,
    String device,
    Map<String, Object?> event,
  ) => switch (type) {
    'device.connected' => '$device connected',
    'device.disconnected' => '$device disconnected',
    'device.reconnecting' => '$device reconnecting…',
    'battery' => '$device battery ${event['percent']}%',
    'clipboard.received' => _clip(device, event),
    'file.received' => _files(device, event),
    'notification.received' => _notification(device, event),
    'call.ringing' => switch (event['caller']) {
      final String caller => '$device call from $caller',
      _ => '$device call ringing',
    },
    'call.ended' => switch (event['missed']) {
      true => '$device missed call',
      _ => '$device call ended',
    },
    'transfer.progress' => _progress(event),
    'transfer.done' => 'Transfer ${event['id']} ${event['result']}',
    'action.run' => '$device ran ${event['action']}: ${event['result']}',
    _ => '$type $device'.trim(),
  };

  static String _clip(String device, Map<String, Object?> event) {
    final kind = '${event['kind']}';
    if (event['text'] case final String text) {
      return '$device sent a clip: $text';
    }

    return '$device sent a clip ($kind)';
  }

  static String _files(String device, Map<String, Object?> event) {
    final count = event['files'];
    final noun = switch (count) {
      1 => 'file',
      _ => 'files',
    };
    final paths = switch (event['paths']) {
      final List<Object?> list when list.isNotEmpty => ': ${list.join(', ')}',
      _ => '',
    };

    return '$device sent $count $noun (${_size(event['bytes'])})$paths';
  }

  static String _notification(String device, Map<String, Object?> event) {
    final app = event['app'];
    final title = switch (event['title']) {
      final String title when title.isNotEmpty => ': $title',
      _ => '',
    };
    final text = switch (event['text']) {
      final String text when text.isNotEmpty => ' · $text',
      _ => '',
    };

    return '$device notification from $app$title$text';
  }

  static String _progress(Map<String, Object?> event) {
    final percent = switch ((event['bytes'], event['total'])) {
      (final int bytes, final int total) when total > 0 =>
        '${bytes * 100 ~/ total}%',
      _ => '',
    };

    return 'Transfer ${event['id']} ${event['direction']} $percent'.trim();
  }

  static String _size(Object? bytes) {
    if (bytes is! int) {
      return '?';
    }

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1000 && unit < units.length - 1) {
      value /= 1000;
      unit++;
    }

    final digits = switch (unit) {
      0 => 0,
      _ => 1,
    };
    return '${value.toStringAsFixed(digits)} ${units[unit]}';
  }

  static String _timeOf(Object? at) {
    final parsed = switch (at) {
      final String text => DateTime.tryParse(text),
      _ => null,
    };
    final local = (parsed ?? DateTime.now()).toLocal();

    return [
      local.hour,
      local.minute,
      local.second,
    ].map((part) => '$part'.padLeft(2, '0')).join(':');
  }
}
