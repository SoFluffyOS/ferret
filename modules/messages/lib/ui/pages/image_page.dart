import 'dart:typed_data';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:messages/l10n/l10n.dart';
import 'package:messages/ui/pages/page_header.dart';
import 'package:messages/ui/widgets/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A picture from a text, in full, fetched from the phone.
class ImagePage extends StatefulWidget {
  const ImagePage({
    super.key,
    required this.phoneName,
    required this.load,
    this.preview,
  });

  final String phoneName;
  final Future<Uint8List?> Function() load;

  /// The small preview, shown while the full picture loads.
  final Uint8List? preview;

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  late final Future<Uint8List?> _image = widget.load();

  @override
  Widget build(BuildContext context) {
    final l10n = context.messagesL10n;

    return ColoredBox(
      color: context.palette.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: .stretch,
          children: [
            PageHeader(
              title: l10n.photo,
              backLabel: l10n.back,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: FutureBuilder<Uint8List?>(
                future: _image,
                builder: (context, snapshot) {
                  final bytes = switch (snapshot.data) {
                    final Uint8List full => full,
                    null => widget.preview,
                  };
                  final failed =
                      snapshot.connectionState == .done &&
                      snapshot.data == null;

                  return Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      if (failed)
                        Padding(
                          padding: EdgeInsets.all(Spacing.d12),
                          child: StatusBanner(
                            text: l10n.imageFailed(widget.phoneName),
                          ),
                        ),
                      if (bytes != null)
                        Expanded(
                          child: InteractiveViewer(
                            child: Image.memory(bytes, fit: .contain),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
