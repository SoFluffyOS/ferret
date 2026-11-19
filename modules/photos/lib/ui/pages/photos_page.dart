import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:photos/ui/frames/frames.dart';
import 'package:photos/view_models/view_models.dart';
import 'package:protocol/photos.dart';
import 'package:provider/provider.dart';

/// A phone's Photos section. Opening it asks the phone again, so a change
/// made there shows right away; thumbnails already fetched stay.
class PhotosPage extends StatefulWidget {
  const PhotosPage({
    super.key,
    required this.viewModel,
    required this.deviceName,
    required this.showsPreviews,
    required this.onOpen,
  });

  final PhotoGalleryViewModel viewModel;
  final String deviceName;
  final bool showsPreviews;
  final void Function(PhotoItem item) onOpen;

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  @override
  void initState() {
    super.initState();
    if (widget.showsPreviews) {
      unawaited(widget.viewModel.load());
    }
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: widget.viewModel,
    child: PhotosGalleryFrame(
      deviceName: widget.deviceName,
      showsPreviews: widget.showsPreviews,
      onOpen: widget.onOpen,
    ),
  );
}
