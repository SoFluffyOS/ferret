import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/models/models.dart';
import 'package:photos/ui/widgets/widgets.dart';
import 'package:photos/view_models/view_models.dart';
import 'package:protocol/photos.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// One photo, larger: a bigger thumbnail kept only in the cache, and Save
/// to bring the full file into the receive folder. Once saved, Open and
/// Show in folder, which is the only way to play a video.
class PhotoPreviewPage extends StatefulWidget {
  const PhotoPreviewPage({
    super.key,
    required this.viewModel,
    required this.item,
    this.dragOut,
  });

  final PhotoGalleryViewModel viewModel;
  final PhotoItem item;

  /// Drags the photo out to other apps; null where that can't be done.
  final DragOut? dragOut;

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  late final Future<Uint8List?> _image = widget.viewModel.thumbnail(
    widget.item.id,
    maxPx: PhotoSizes.preview,
  );
  PhotoTransferStatus? _status;
  late String? _savedPath = widget.viewModel.localCopy(widget.item.id);

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

    // Like Preview, the whole photo shows without scrolling: a tall one
    // gets narrower rather than taller than the view.
    final maxHeight = MediaQuery.sizeOf(context).height * _maxHeightShare;

    return FerretPage(
      title: title,
      titleStyle: .inline,
      backLabel: l10n.back,
      actions: switch (_savedPath) {
        final path? => [
          GhostButton(
            mainAxisSize: .min,
            label: switch (defaultTargetPlatform) {
              .macOS => l10n.revealSavedFinder,
              _ => l10n.revealSaved,
            },
            onPressed: () => unawaited(widget.viewModel.reveal(path)),
          ),
          Button(
            variant: .primary,
            mainAxisSize: .min,
            label: l10n.openSaved,
            onPressed: () => unawaited(widget.viewModel.open(path)),
          ),
        ],
        null => [
          Button(
            variant: .primary,
            mainAxisSize: .min,
            label: l10n.save,
            enable: _status != .running && _status != .done,
            onPressed: () => unawaited(_saveIt()),
          ),
        ],
      },
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: AspectRatio(
              aspectRatio: _aspect(item),
              child: _draggable(
                context,
                child: ClipRSuperellipse(
                  borderRadius: Corners.radius(Corners.card),
                  child: ColoredBox(
                    color: palette.surface,
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
            ),
          ),
        ),
        Spacing.v12,
        Text(
          note,
          textAlign: .center,
          style: typography.base2.copyWith(color: palette.mutedText),
        ),
      ],
    );
  }

  /// The photo itself drags out to Finder or another app, as in Preview.
  Widget _draggable(BuildContext context, {required Widget child}) {
    final dragOut = widget.dragOut;
    if (dragOut == null) {
      return child;
    }

    return GestureDetector(
      onPanStart: (_) => unawaited(
        PhotoDrag.start(
          context,
          dragOut: dragOut,
          viewModel: widget.viewModel,
          items: [widget.item],
        ),
      ),
      child: child,
    );
  }

  Future<void> _saveIt() async {
    setState(() => _status = .running);
    final save = await widget.viewModel.save([widget.item.id]);
    if (!mounted) {
      return;
    }

    setState(() {
      _status = save.status;
      _savedPath = switch (save) {
        PhotoSave(status: .done, paths: [final path, ...]) => path,
        _ => null,
      };
    });
  }

  static const _maxHeightShare = 0.7;

  static double _aspect(PhotoItem item) {
    if (item.width == 0 || item.height == 0) {
      return 1;
    }

    return item.width / item.height;
  }
}
