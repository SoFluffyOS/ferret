import 'dart:async';
import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/models/models.dart';
import 'package:photos/ui/widgets/widgets.dart';
import 'package:photos/view_models/view_models.dart';
import 'package:protocol/photos.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One photo, larger: a bigger thumbnail kept only in the cache, and Save
/// to bring the full file into the receive folder.
class PhotoPreviewPage extends StatefulWidget {
  const PhotoPreviewPage({
    super.key,
    required this.viewModel,
    required this.item,
  });

  final PhotoGalleryViewModel viewModel;
  final PhotoItem item;

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  late final Future<Uint8List?> _image = widget.viewModel.thumbnail(
    widget.item.id,
    maxPx: PhotoSizes.preview,
  );
  PhotoTransferStatus? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.photosL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final item = widget.item;
    final date = PhotoDate.format(
      locale,
      DateTime.fromMillisecondsSinceEpoch(item.takenAtMs.toInt()),
    );
    final title = switch (item.name) {
      '' => date,
      final name => name,
    };
    final note = switch (_status) {
      .running => l10n.saving,
      .done => l10n.saved,
      .failed => l10n.saveFailed,
      null => date,
    };

    return FerretPage(
      title: title,
      backLabel: l10n.back,
      actions: [
        Button(
          variant: .primary,
          mainAxisSize: .min,
          label: l10n.save,
          enable: _status != .running && _status != .done,
          onPressed: () => unawaited(_save()),
        ),
      ],
      children: [
        ClipRSuperellipse(
          borderRadius: Corners.radius(Corners.card),
          child: ColoredBox(
            color: palette.surface,
            child: AspectRatio(
              aspectRatio: _aspect(item),
              child: FutureBuilder<Uint8List?>(
                future: _image,
                builder: (context, snapshot) {
                  if (snapshot.data case final bytes?) {
                    return Image.memory(bytes, fit: .contain);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
        Spacing.v12,
        Text(
          note,
          style: typography.base2.copyWith(color: palette.mutedText),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _status = .running);
    final save = await widget.viewModel.save([widget.item.id]);
    if (!mounted) {
      return;
    }

    setState(() => _status = save.status);
  }

  static double _aspect(PhotoItem item) {
    if (item.width == 0 || item.height == 0) {
      return 1;
    }

    return item.width / item.height;
  }
}
