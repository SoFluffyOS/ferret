import 'dart:async';

import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:drop/ui/widgets/widgets.dart';
import 'package:drop/view_models/view_models.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

/// Asks which device should get the files: a connected paired device, or
/// a LocalSend device on the network. Opening it looks for LocalSend
/// devices, and the list fills in as they answer. For a shared link it
/// also offers to open the link on the devices in [opensOn].
class DevicePickerDialog extends StatefulWidget {
  const DevicePickerDialog({super.key, this.opensOn = const []});

  /// Devices that can open a shared link right away.
  final List<DropTarget> opensOn;

  static Future<DropTarget?> show(
    BuildContext context,
    DropViewModel viewModel,
  ) async => (await _show(context, viewModel, const []))?.target;

  /// Asks where a shared link goes: as text to a device, or open on one of
  /// [opensOn].
  static Future<DropPick?> showForLink(
    BuildContext context,
    DropViewModel viewModel, {
    required List<DropTarget> opensOn,
  }) => _show(context, viewModel, opensOn);

  static Future<DropPick?> _show(
    BuildContext context,
    DropViewModel viewModel,
    List<DropTarget> opensOn,
  ) => showGeneralDialog<DropPick>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.dropL10n.actionCancel,
    barrierColor: FluffyColors.barrier,
    pageBuilder: (_, _, _) => ChangeNotifierProvider.value(
      value: viewModel,
      child: DevicePickerDialog(opensOn: opensOn),
    ),
  );

  @override
  State<DevicePickerDialog> createState() => _DevicePickerDialogState();
}

class _DevicePickerDialogState extends State<DevicePickerDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<DropViewModel>().scan());
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DropViewModel>();
    final paired = context.select<DropViewModel, List<DropTarget>>(
      (model) => model.targets,
    );
    final nearby = context.select<DropViewModel, List<DropTarget>>(
      (model) => model.localSendTargets,
    );
    final localSend = context.select<DropViewModel, bool>(
      (model) => model.localSendEnabled,
    );
    final scanning = context.select<DropViewModel, bool>(
      (model) => model.isScanning,
    );
    final palette = context.palette;
    final typography = context.fluffyTheme.typography;
    final l10n = context.dropL10n;
    final hint = typography.caption1.copyWith(color: palette.mutedText);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Spacing.d320),
        child: DialogShape(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  switch (widget.opensOn.isEmpty) {
                    true => l10n.pickerTitle,
                    false => l10n.pickerLinkTitle,
                  },
                  textAlign: .center,
                  style: typography.title3.copyWith(color: palette.text),
                ),
                Spacing.v16,
                if (paired.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: Spacing.d8),
                    child: Text(l10n.pickerNoDevices, style: hint),
                  ),
                for (final target in paired) TargetButton(target: target),
                if (widget.opensOn.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      top: Spacing.d8,
                      bottom: Spacing.d8,
                    ),
                    child: Text(l10n.pickerOpenTitle, style: hint),
                  ),
                for (final target in widget.opensOn)
                  TargetButton(
                    target: target,
                    opens: true,
                    label: l10n.pickerOpenOn(target.name),
                  ),
                for (final target in nearby)
                  TargetButton(
                    target: target,
                    caption: switch (target.detail.isEmpty) {
                      true => l10n.pickerLocalSend,
                      false => l10n.pickerLocalSendModel(target.detail),
                    },
                  ),
                if (localSend && scanning)
                  Text(l10n.pickerScanning, style: hint),
                if (localSend && !scanning && nearby.isEmpty)
                  Text(l10n.pickerNoLocalSend, style: hint),
                if (localSend && !scanning)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GhostButton(
                      mainAxisSize: .min,
                      label: l10n.pickerSearchAgain,
                      onPressed: () => unawaited(viewModel.scan()),
                    ),
                  ),
                Spacing.v8,
                GhostButton(
                  label: l10n.actionCancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
