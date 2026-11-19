/// How full the battery is, from 0 to 100, and whether it charges.
class BatteryLevel {
  const BatteryLevel(this.percent, {required this.charging});

  final int percent;
  final bool charging;

  @override
  bool operator ==(Object other) =>
      other is BatteryLevel &&
      other.percent == percent &&
      other.charging == charging;

  @override
  int get hashCode => Object.hash(percent, charging);

  @override
  String toString() =>
      'BatteryLevel($percent%${switch (charging) {
        true => ', charging',
        false => '',
      }})';
}
