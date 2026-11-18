/// One line of the tray icon's menu. A [separator] has no title and no id.
class TrayMenuItem {
  const TrayMenuItem({
    required this.id,
    required this.title,
    this.enabled = true,
  }) : separator = false;

  const TrayMenuItem.separator()
    : id = '',
      title = '',
      enabled = false,
      separator = true;

  /// What the tray reports when this line is picked.
  final String id;
  final String title;
  final bool enabled;
  final bool separator;

  Map<String, Object> toMap() => {
    'id': id,
    'title': title,
    'enabled': enabled,
    'separator': separator,
  };

  @override
  bool operator ==(Object other) =>
      other is TrayMenuItem &&
      other.id == id &&
      other.title == title &&
      other.enabled == enabled &&
      other.separator == separator;

  @override
  int get hashCode => Object.hash(id, title, enabled, separator);
}
