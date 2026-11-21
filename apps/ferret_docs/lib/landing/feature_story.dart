/// One feature group on the landing: what it does, a render, and its docs.
class FeatureStory {
  const FeatureStory({
    required this.id,
    required this.icon,
    required this.title,
    required this.lead,
    required this.points,
    required this.shot,
    required this.alt,
    required this.width,
    required this.height,
    required this.docs,
    required this.docsLabel,
    required this.frame,
    this.isBeta = false,
  });

  final String id;
  final String icon;
  final String title;
  final String lead;
  final List<String> points;
  final String shot;
  final String alt;
  final int width;
  final int height;
  final String docs;
  final String docsLabel;
  final ShotFrame frame;

  /// Works in my tests but hasn't met enough real devices yet.
  final bool isBeta;
}

/// What a render shows, so it gets the right corners around it: a computer
/// window, the Mac menubar popover, or a phone screen.
enum ShotFrame { window, popover, phone }

/// A smaller feature without a render.
typedef FeatureExtra = ({String icon, String title, String body, String docs});

/// One question in the FAQ, with an optional link to read more.
typedef FaqEntry = ({String question, String answer, String? link});

/// One platform in the download section.
///
/// [download] is a file in the latest GitHub release, named the same on
/// every release; [command] is a line to paste instead (Linux); with
/// neither, the platform isn't out yet.
typedef PlatformEntry = ({
  String icon,
  String name,
  String how,
  String guide,
  String? download,
  String? downloadLabel,
  String? command,
});
