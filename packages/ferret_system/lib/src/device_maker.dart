/// Phone makers that add their own battery killer on top of Android's, so
/// the app can show the right steps to keep Ferret running.
enum DeviceMaker {
  xiaomi,
  samsung,
  oneplus,
  huawei,
  oppo,
  vivo,
  other;

  /// The maker for Android's `Build.MANUFACTURER`, including sub-brands
  /// that share the same system apps (Redmi, POCO, Honor, realme, iQOO).
  static DeviceMaker fromManufacturer(String manufacturer) =>
      switch (manufacturer.trim().toLowerCase()) {
        'xiaomi' || 'redmi' || 'poco' => xiaomi,
        'samsung' => samsung,
        'oneplus' => oneplus,
        'huawei' || 'honor' => huawei,
        'oppo' || 'realme' => oppo,
        'vivo' || 'iqoo' => vivo,
        _ => other,
      };

  /// Whether the maker is known to stop background apps beyond Android's
  /// own battery optimization.
  bool get hasExtraKiller => this != other;
}
