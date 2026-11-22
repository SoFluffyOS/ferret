/// One file attached to a release, such as `Ferret-mac.dmg`.
class UpdateAsset {
  const UpdateAsset({
    required this.name,
    required this.downloadUrl,
    this.size = 0,
  });

  factory UpdateAsset.fromJson(Map<String, Object?> json) => UpdateAsset(
    name: switch (json['name']) {
      final String name => name,
      _ => '',
    },
    downloadUrl: switch (json['browser_download_url']) {
      final String url => Uri.tryParse(url) ?? Uri(),
      _ => Uri(),
    },
    size: switch (json['size']) {
      final int size => size,
      _ => 0,
    },
  );

  final String name;
  final Uri downloadUrl;

  /// In bytes, or 0 when the release didn't say.
  final int size;
}
