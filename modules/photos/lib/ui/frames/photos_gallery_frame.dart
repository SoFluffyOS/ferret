import 'dart:async';

import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:photos/l10n/l10n.dart';
import 'package:photos/models/models.dart';
import 'package:photos/ui/widgets/widgets.dart';
import 'package:photos/view_models/view_models.dart';
import 'package:protocol/photos.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// A phone's photos on this computer: newest first, in a grid that asks
/// for more as its end comes into view. Select some to save them, or open
/// one to look closer.
class PhotosGalleryFrame extends StatelessWidget {
  const PhotosGalleryFrame({
    super.key,
    required this.deviceName,
    required this.showsPreviews,
    required this.onOpen,
    this.dragOut,
  });

  final String deviceName;

  /// False while previews from this phone are hidden here: nothing is
  /// asked for or drawn.
  final bool showsPreviews;
  final void Function(PhotoItem item) onOpen;

  /// Drags photos out to other apps; null where that can't be done.
  final DragOut? dragOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.photosL10n;
    final state = context.select<PhotoGalleryViewModel, GalleryState>(
      (viewModel) => viewModel.state,
    );
    final items = context.select<PhotoGalleryViewModel, List<PhotoItem>>(
      (viewModel) => viewModel.items,
    );
    final isSelecting = context.select<PhotoGalleryViewModel, bool>(
      (viewModel) => viewModel.isSelecting,
    );
    final selected = context.select<PhotoGalleryViewModel, Set<String>>(
      (viewModel) => viewModel.selected,
    );
    final isLimited = context.select<PhotoGalleryViewModel, bool>(
      (viewModel) => viewModel.isLimited,
    );
    final hasMore = context.select<PhotoGalleryViewModel, bool>(
      (viewModel) => viewModel.hasMore,
    );
    final autoScreenshots = context.select<PhotoGalleryViewModel, bool>(
      (viewModel) => viewModel.autoScreenshots,
    );
    final viewModel = context.read<PhotoGalleryViewModel>();
    final columns = switch (context.screenSize) {
      .small => 3,
      .normal => 4,
      _ => 5,
    };
    final showsGrid = showsPreviews && state == .photos;

    return FerretPage(
      title: l10n.title,
      backLabel: l10n.back,
      children: [
        GroupedCard(
          children: [
            SettingSwitchRow(
              title: l10n.autoScreenshots,
              body: l10n.autoScreenshotsBody(deviceName),
              value: autoScreenshots,
              onChanged: (value) =>
                  unawaited(viewModel.setAutoScreenshots(value)),
            ),
          ],
        ),
        Spacing.v16,
        if (!showsPreviews)
          GalleryMessage(
            icon: LucideIcons.eyeOff,
            title: l10n.hidden(deviceName, ThisComputer.here),
          ),
        if (showsPreviews && state != .photos)
          _message(context, state, viewModel),
        if (showsGrid && isLimited) _LimitedBanner(deviceName: deviceName),
        if (showsGrid)
          SectionTitle(
            l10n.recent,
            trailing: Row(
              mainAxisSize: .min,
              children: _selectionActions(context, isSelecting, selected),
            ),
          ),
        if (showsGrid && dragOut != null)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              PageInsets.row,
              0,
              PageInsets.row,
              Spacing.d8,
            ),
            child: Text(
              l10n.dragHint,
              style: context.fluffyTheme.typography.caption1.copyWith(
                color: context.palette.mutedText,
              ),
            ),
          ),
        if (showsGrid)
          for (var start = 0; start < items.length; start += columns)
            Padding(
              padding: EdgeInsets.only(bottom: Spacing.d4),
              child: _GridRow(
                items: items.skip(start).take(columns).toList(),
                columns: columns,
                isSelecting: isSelecting,
                selected: selected,
                onOpen: onOpen,
                dragOut: dragOut,
              ),
            ),
        if (showsGrid && hasMore)
          _LoadMore(
            key: ValueKey(items.length),
            onVisible: viewModel.loadMore,
          ),
      ],
    );
  }

  List<Widget> _selectionActions(
    BuildContext context,
    bool isSelecting,
    Set<String> selected,
  ) {
    final l10n = context.photosL10n;
    final viewModel = context.read<PhotoGalleryViewModel>();
    if (!isSelecting) {
      return [
        TextLink(
          label: l10n.select,
          onTap: () => viewModel.setSelecting(true),
        ),
      ];
    }

    return [
      TextLink(
        label: l10n.cancel,
        onTap: () => viewModel.setSelecting(false),
      ),
      Spacing.h12,
      Button(
        variant: .primary,
        mainAxisSize: .min,
        label: l10n.saveCount(selected.length),
        enable: selected.isNotEmpty,
        onPressed: () => unawaited(viewModel.save()),
      ),
    ];
  }

  Widget _message(
    BuildContext context,
    GalleryState state,
    PhotoGalleryViewModel viewModel,
  ) {
    final l10n = context.photosL10n;
    final asked = context.select<PhotoGalleryViewModel, bool>(
      (viewModel) => viewModel.askedForAccess,
    );
    final askButton = Button(
      variant: .primary,
      mainAxisSize: .min,
      label: l10n.askShort,
      tooltip: l10n.askOnDevice(deviceName),
      semanticLabel: l10n.askOnDevice(deviceName),
      onPressed: () => unawaited(viewModel.askForAccess()),
    );
    final tryAgain = Button(
      variant: .primary,
      mainAxisSize: .min,
      label: l10n.tryAgain,
      onPressed: () => unawaited(viewModel.load()),
    );
    final askedNote = switch (asked) {
      true => l10n.askedOnDevice(deviceName),
      false => null,
    };

    return switch (state) {
      .loading => GalleryMessage(
        icon: LucideIcons.images,
        title: l10n.loading(deviceName),
      ),
      .offline => GalleryMessage(
        icon: LucideIcons.wifiOff,
        title: l10n.offline(deviceName),
      ),
      .unsupported => GalleryMessage(
        icon: LucideIcons.circleAlert,
        title: l10n.unsupported(deviceName),
      ),
      .failed => GalleryMessage(
        icon: LucideIcons.circleAlert,
        title: l10n.failed(deviceName),
        action: tryAgain,
      ),
      .notAllowed => GalleryMessage(
        icon: LucideIcons.lock,
        title: l10n.notAllowedTitle(deviceName),
        body: l10n.notAllowedBody(deviceName, ThisComputer.here),
        action: askButton,
        note: askedNote,
      ),
      .noPermission => GalleryMessage(
        icon: LucideIcons.imageOff,
        title: l10n.noPermissionTitle(deviceName),
        body: l10n.noPermissionBody(deviceName),
        action: askButton,
        note: askedNote,
      ),
      .unavailable => GalleryMessage(
        icon: LucideIcons.smartphone,
        title: l10n.unavailableTitle(deviceName),
        body: l10n.unavailableBody,
        action: tryAgain,
      ),
      .empty => GalleryMessage(
        icon: LucideIcons.images,
        title: l10n.empty(deviceName),
      ),
      .photos => const SizedBox.shrink(),
    };
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    required this.items,
    required this.columns,
    required this.isSelecting,
    required this.selected,
    required this.onOpen,
    required this.dragOut,
  });

  final List<PhotoItem> items;
  final int columns;
  final bool isSelecting;
  final Set<String> selected;
  final void Function(PhotoItem item) onOpen;
  final DragOut? dragOut;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PhotoGalleryViewModel>();
    final l10n = context.photosL10n;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Row(
      children: [
        for (var index = 0; index < columns; index++) ...[
          if (index > 0) Spacing.h4,
          Expanded(
            child: switch (index < items.length) {
              true => _tile(context, viewModel, l10n, locale, items[index]),
              false => const SizedBox.shrink(),
            },
          ),
        ],
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    PhotoGalleryViewModel viewModel,
    PhotosLocalizations l10n,
    String locale,
    PhotoItem item,
  ) {
    final date = PhotoDate.format(
      locale,
      DateTime.fromMillisecondsSinceEpoch(item.takenAtMs.toInt()),
    );
    final label = switch (item.kind) {
      .PHOTO_KIND_SCREENSHOT => l10n.kindScreenshot(date),
      .PHOTO_KIND_VIDEO => l10n.kindVideo(date),
      _ => l10n.kindPhoto(date),
    };

    return PhotoTile(
      key: ValueKey(item.id),
      loadThumbnail: () => viewModel.thumbnail(item.id, maxPx: PhotoSizes.tile),
      semanticLabel: label,
      isVideo: item.kind == .PHOTO_KIND_VIDEO,
      isSelecting: isSelecting,
      isSelected: selected.contains(item.id),
      onLongPress: () => viewModel.toggle(item.id),
      onDragStart: switch (dragOut) {
        final dragOut? => () => unawaited(
          PhotoDrag.start(
            context,
            dragOut: dragOut,
            viewModel: viewModel,
            items: viewModel.dragged(item),
          ),
        ),
        null => null,
      },
      onTap: () {
        if (isSelecting) {
          viewModel.toggle(item.id);
          return;
        }

        onOpen(item);
      },
    );
  }
}

class _LimitedBanner extends StatelessWidget {
  const _LimitedBanner({required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.photosL10n;
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final viewModel = context.read<PhotoGalleryViewModel>();
    final asked = context.select<PhotoGalleryViewModel, bool>(
      (viewModel) => viewModel.askedForAccess,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: Spacing.d12),
      child: SurfaceCard(
        child: Row(
          children: [
            Icon(LucideIcons.images, size: Spacing.d20, color: palette.text),
            Spacing.h12,
            Expanded(
              child: Text(
                switch (asked) {
                  true => l10n.askedOnDevice(deviceName),
                  false => l10n.limited(deviceName),
                },
                style: typography.base2.copyWith(color: palette.text),
              ),
            ),
            Spacing.h8,
            GhostButton(
              mainAxisSize: .min,
              label: l10n.allowMore,
              onPressed: () => unawaited(viewModel.askForAccess()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the next page once it is built, which a list does only as its
/// end comes near the screen.
class _LoadMore extends StatefulWidget {
  const _LoadMore({super.key, required this.onVisible});

  final Future<void> Function() onVisible;

  @override
  State<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<_LoadMore> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(widget.onVisible()),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(height: Spacing.d40);
}
