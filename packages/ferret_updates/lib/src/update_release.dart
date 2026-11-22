import 'package:ferret_updates/src/release_version.dart';
import 'package:ferret_updates/src/update_asset.dart';

/// A published release: its version, what's new, and its files.
class UpdateRelease {
  const UpdateRelease({
    required this.tag,
    required this.notes,
    required this.assets,
    this.preRelease = false,
    this.draft = false,
    this.pageUrl,
  });

  /// GitHub's release JSON.
  factory UpdateRelease.fromJson(Map<String, Object?> json) => UpdateRelease(
    tag: switch (json['tag_name']) {
      final String tag => tag,
      _ => '',
    },
    notes: switch (json['body']) {
      final String body => body,
      _ => '',
    },
    preRelease: json['prerelease'] == true,
    draft: json['draft'] == true,
    pageUrl: switch (json['html_url']) {
      final String url => Uri.tryParse(url),
      _ => null,
    },
    assets: [
      if (json['assets'] case final List<Object?> entries)
        for (final entry in entries)
          if (entry case final Map<String, Object?> asset)
            UpdateAsset.fromJson(asset),
    ],
  );

  /// The tag, such as `v0.2.0`.
  final String tag;

  /// The release notes, in Markdown.
  final String notes;
  final List<UpdateAsset> assets;
  final bool preRelease;
  final bool draft;

  /// The release's page on GitHub, for a download by hand.
  final Uri? pageUrl;

  ReleaseVersion? get version => ReleaseVersion.tryParse(tag);

  /// The version as people read it: `0.2.0`, without the tag's `v`.
  String get versionText => version?.toString() ?? tag;

  UpdateAsset? assetNamed(String name) {
    for (final asset in assets) {
      if (asset.name == name) {
        return asset;
      }
    }

    return null;
  }
}
