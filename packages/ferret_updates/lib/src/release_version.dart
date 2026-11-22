/// A release's version, such as `v0.2.0`, `0.2.0+3` or `0.3.0-beta.1`,
/// ordered the way semantic versioning orders them: numbers part by part,
/// and a test version (`-beta.1`) before the release it leads to.
final class ReleaseVersion implements Comparable<ReleaseVersion> {
  const ReleaseVersion(this.numbers, {this.preRelease = const []});

  /// The numbers before any `-` or `+`, such as `[0, 2, 0]`.
  final List<int> numbers;

  /// What follows a `-`, split at dots, such as `['beta', '1']`. Empty for a
  /// release.
  final List<String> preRelease;

  bool get isPreRelease => preRelease.isNotEmpty;

  /// Reads [text], with or without a leading `v`; build numbers after `+`
  /// don't count. Null when it doesn't start with a number.
  static ReleaseVersion? tryParse(String text) {
    final trimmed = text.trim();
    final bare = switch (trimmed.startsWith('v') || trimmed.startsWith('V')) {
      true => trimmed.substring(1),
      false => trimmed,
    };
    final withoutBuild = bare.split('+').first;
    final dash = withoutBuild.indexOf('-');
    final core = switch (dash) {
      -1 => withoutBuild,
      _ => withoutBuild.substring(0, dash),
    };
    final tag = switch (dash) {
      -1 => '',
      _ => withoutBuild.substring(dash + 1),
    };

    final numbers = <int>[];
    for (final part in core.split('.')) {
      final number = int.tryParse(part);
      if (number == null || number < 0) {
        return null;
      }

      numbers.add(number);
    }

    return ReleaseVersion(
      numbers,
      preRelease: [
        for (final part in tag.split('.'))
          if (part.isNotEmpty) part,
      ],
    );
  }

  @override
  int compareTo(ReleaseVersion other) {
    final length = switch (numbers.length > other.numbers.length) {
      true => numbers.length,
      false => other.numbers.length,
    };
    for (var index = 0; index < length; index++) {
      final mine = _at(numbers, index);
      final theirs = _at(other.numbers, index);
      if (mine != theirs) {
        return mine.compareTo(theirs);
      }
    }

    return _comparePreRelease(preRelease, other.preRelease);
  }

  bool operator >(ReleaseVersion other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is ReleaseVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(_trimmed(numbers)),
    Object.hashAll(preRelease),
  );

  @override
  String toString() => switch (preRelease.isEmpty) {
    true => numbers.join('.'),
    false => '${numbers.join('.')}-${preRelease.join('.')}',
  };

  static int _at(List<int> numbers, int index) =>
      switch (index < numbers.length) {
        true => numbers[index],
        false => 0,
      };

  static List<int> _trimmed(List<int> numbers) {
    var end = numbers.length;
    while (end > 0 && numbers[end - 1] == 0) {
      end--;
    }

    return numbers.sublist(0, end);
  }

  static int _comparePreRelease(List<String> mine, List<String> theirs) {
    if (mine.isEmpty && theirs.isEmpty) {
      return 0;
    }

    if (mine.isEmpty) {
      return 1;
    }

    if (theirs.isEmpty) {
      return -1;
    }

    for (var index = 0; index < mine.length && index < theirs.length; index++) {
      final order = _compareIdentifier(mine[index], theirs[index]);
      if (order != 0) {
        return order;
      }
    }

    return mine.length.compareTo(theirs.length);
  }

  static int _compareIdentifier(String mine, String theirs) {
    final (myNumber, theirNumber) = (int.tryParse(mine), int.tryParse(theirs));
    return switch ((myNumber, theirNumber)) {
      (final left?, final right?) => left.compareTo(right),
      (_?, null) => -1,
      (null, _?) => 1,
      (null, null) => mine.compareTo(theirs),
    };
  }
}

/// Whether [latest] is a later version than [current]. A version that
/// can't be read is never newer.
bool isNewerVersion(String latest, String current) {
  final (newer, older) = (
    ReleaseVersion.tryParse(latest),
    ReleaseVersion.tryParse(current),
  );
  if (newer == null || older == null) {
    return false;
  }

  return newer > older;
}
