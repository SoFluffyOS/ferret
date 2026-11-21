import 'package:feature_kit/layout/corners.dart';
import 'package:feature_kit/theme/theme.dart';
import 'package:feature_kit/widgets/surface_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

bool get _underPointer => switch (defaultTargetPlatform) {
  .macOS || .windows || .linux => true,
  .android || .iOS || .fuchsia => false,
};

/// The shape of a dialog Ferret draws. On a phone or a tablet it is
/// [Corners.dialog], with its content [Corners.dialogInset] from the sides
/// and the bottom, so a button at the bottom corner is concentric with the
/// dialog. Under a pointer it is a [SurfaceCard], as before.
class DialogShape extends StatelessWidget {
  const DialogShape({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_underPointer) {
      return SurfaceCard(padding: EdgeInsets.all(Spacing.d20), child: child);
    }

    final palette = context.palette;
    final inset = Corners.dialogInset;

    // No outline, so in dark mode the dialog is lifted off the dimmed page
    // by its fill, as the system's alerts are.
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: switch (context.isDark) {
          true => palette.surface,
          false => palette.background,
        },
        shape: Corners.shape(Corners.dialog),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(inset, Spacing.d24, inset, inset),
        child: child,
      ),
    );
  }
}

/// The design system's `DialogCard` with Ferret's dialog shape on a phone
/// or a tablet ([DialogShape]), and no border. Under a pointer it is the
/// design system's own.
class FerretDialogCard extends StatelessWidget {
  const FerretDialogCard({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.maxWidth,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    if (_underPointer) {
      return DialogCard(
        title: title,
        content: content,
        actions: actions,
        maxWidth: maxWidth,
      );
    }

    final theme = context.fluffyTheme;
    final text = switch (context.isDark) {
      true => theme.colors.neutral1,
      false => theme.colors.neutral7,
    };

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.d16,
          vertical: Spacing.d24,
        ),
        child: DialogShape(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: Spacing.d280,
              maxWidth: maxWidth ?? Spacing.d360,
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .stretch,
              children: [
                if (title case final heading?) ...[
                  DefaultTextStyle(
                    style: theme.typography.headline6.copyWith(
                      color: text,
                      fontWeight: .w600,
                    ),
                    child: heading,
                  ),
                  Spacing.v16,
                ],
                if (content case final body?)
                  Flexible(
                    child: DefaultTextStyle(
                      style: theme.typography.base2.copyWith(color: text),
                      child: body,
                    ),
                  ),
                if (actions case final buttons? when buttons.isNotEmpty) ...[
                  Spacing.v24,
                  ...buttons,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> _showDialog<T>(
  BuildContext context, {
  required bool barrierDismissible,
  required String barrierLabel,
  required Widget Function(BuildContext context) builder,
}) {
  final fluffyTheme = context.fluffyTheme;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: FluffyColors.barrier,
    transitionDuration: FluffyDurations.dialogTransition,
    transitionBuilder: (context, animation, _, child) =>
        FluffyDialogTransition(animation: animation, child: child),
    pageBuilder: (context, _, _) =>
        FluffyTheme(data: fluffyTheme, child: builder(context)),
  );
}

/// Two buttons side by side, each half the dialog's width, as the design
/// system lays them out on a phone.
Widget _answers({
  String? ghost,
  VoidCallback? onGhost,
  required String primary,
  required VoidCallback onPrimary,
}) => Row(
  children: [
    if (ghost case final label?) ...[
      Expanded(
        child: Button(
          variant: .ghost,
          tooltip: label,
          label: label,
          titleExpand: .shrink,
          onPressed: onGhost,
        ),
      ),
      Spacing.h8,
    ],
    Expanded(
      child: Button(
        variant: .primary,
        tooltip: primary,
        label: primary,
        titleExpand: .shrink,
        onPressed: onPrimary,
      ),
    ),
  ],
);

/// The design system's `ConfirmDialog` in [FerretDialogCard].
abstract final class FerretConfirmDialog {
  static Future<ConfirmAction> show(
    BuildContext context, {
    required String title,
    String? message,
    required String negativeText,
    required String positiveText,
    bool barrierDismissible = true,
    String barrierLabel = 'Dismiss',
  }) async {
    if (_underPointer) {
      return ConfirmDialog.show(
        context,
        title: title,
        message: message,
        negativeText: negativeText,
        positiveText: positiveText,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
      );
    }

    final result = await _showDialog<ConfirmAction>(
      context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      builder: (context) {
        void answer(ConfirmAction action) => context.navigator.pop(action);

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): () =>
                answer(.positive),
            const SingleActivator(LogicalKeyboardKey.numpadEnter): () =>
                answer(.positive),
          },
          child: Focus(
            autofocus: true,
            child: FerretDialogCard(
              title: Text(title),
              content: switch (message) {
                final words? when words.isNotEmpty => Text(words),
                _ => null,
              },
              actions: [
                _answers(
                  ghost: negativeText,
                  onGhost: () => answer(.negative),
                  primary: positiveText,
                  onPrimary: () => answer(.positive),
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? .dismiss;
  }
}

/// The design system's `InputTextDialog` in [FerretDialogCard].
abstract final class FerretTextDialog {
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String labelText,
    String? hintText,
    required String cancelText,
    required String confirmText,
    String initialValue = '',
    String barrierLabel = 'Dismiss',
  }) async {
    if (_underPointer) {
      return InputTextDialog.show(
        context,
        title: title,
        labelText: labelText,
        hintText: hintText,
        cancelText: cancelText,
        confirmText: confirmText,
        initialValue: initialValue,
        barrierLabel: barrierLabel,
      );
    }

    // A prefilled value starts selected, so typing replaces it.
    final controller = TextEditingController.fromValue(
      TextEditingValue(
        text: initialValue,
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: initialValue.length,
        ),
      ),
    );
    final focusNode = FocusNode(debugLabel: 'FerretTextDialog');
    try {
      return await _showDialog<String>(
        context,
        barrierDismissible: false,
        barrierLabel: barrierLabel,
        builder: (context) {
          void confirm() => context.navigator.pop(controller.text);

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): confirm,
              const SingleActivator(LogicalKeyboardKey.numpadEnter): confirm,
            },
            child: FerretDialogCard(
              title: Text(title),
              content: _AutofocusInput(
                focusNode: focusNode,
                child: InputText(
                  controller: controller,
                  focusNode: focusNode,
                  label: labelText,
                  hintText: hintText,
                  onSubmitted: (_) => confirm(),
                ),
              ),
              actions: [
                _answers(
                  ghost: cancelText,
                  onGhost: () => context.navigator.pop(),
                  primary: confirmText,
                  onPrimary: confirm,
                ),
              ],
            ),
          );
        },
      );
    } finally {
      controller.dispose();
      focusNode.dispose();
    }
  }
}

/// The design system's `ContentDialog` with one button, in
/// [FerretDialogCard]: a longer text that scrolls, and OK.
abstract final class FerretContentDialog {
  static Future<void> show(
    BuildContext context, {
    String? title,
    required String content,
    required String neutralText,
    String barrierLabel = 'Dismiss',
  }) async {
    if (_underPointer) {
      await ContentDialog.show(
        context,
        title: title,
        content: content,
        neutralText: neutralText,
        barrierLabel: barrierLabel,
      );
      return;
    }

    final controller = ScrollController();
    try {
      await _showDialog<void>(
        context,
        barrierDismissible: true,
        barrierLabel: barrierLabel,
        builder: (context) {
          void close() => context.navigator.pop();

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): close,
              const SingleActivator(LogicalKeyboardKey.numpadEnter): close,
            },
            child: Focus(
              autofocus: true,
              child: FerretDialogCard(
                title: switch (title) {
                  final heading? => Text(heading),
                  null => null,
                },
                content: RawScrollbar(
                  controller: controller,
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Text(content),
                  ),
                ),
                actions: [_answers(primary: neutralText, onPrimary: close)],
              ),
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }
}

/// Puts the cursor in the dialog's field when it opens, so the user can
/// type straight away.
class _AutofocusInput extends StatefulWidget {
  const _AutofocusInput({required this.focusNode, required this.child});

  final FocusNode focusNode;
  final Widget child;

  @override
  State<_AutofocusInput> createState() => _AutofocusInputState();
}

class _AutofocusInputState extends State<_AutofocusInput> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
