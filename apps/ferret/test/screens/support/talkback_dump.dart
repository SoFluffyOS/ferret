import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screen_harness.dart';

/// Run the screen tests with `--dart-define=FERRET_TALKBACK=true` to write,
/// next to every phone capture, what TalkBack would find on that screen:
/// `temp/screens/talkback/<name>.txt`, one line per stop in reading order.
const talkbackDumps = bool.fromEnvironment('FERRET_TALKBACK');

/// A stop's label with this many lines or more is several things read as
/// one: worth a look.
const _blobLines = 4;

/// Writes the semantics tree on screen now as TalkBack's stops: role,
/// state, label, value, hint, size in dp, and what is off (a label that
/// is several things at once, a tap target under 48 dp, a text field
/// without a name).
Future<void> writeTalkbackDump(WidgetTester tester, String name) async {
  final semantics = tester.ensureSemantics();
  try {
    await tester.pump();
    final lines = <String>[];
    for (final view in tester.binding.renderViews) {
      final root = view.owner?.semanticsOwner?.rootSemanticsNode;
      if (root != null) {
        _visit(root, 0, lines, Matrix4.identity());
      }
    }

    await tester.runAsync(() async {
      final directory = Directory('${screensDirectory.path}/talkback');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.txt',
      ).writeAsString('${lines.join('\n')}\n');
    });
  } finally {
    semantics.dispose();
  }
}

void _visit(SemanticsNode node, int depth, List<String> lines, Matrix4 m) {
  final transform = Matrix4.copy(m);
  if (node.transform case final own?) {
    transform.multiply(own);
  }

  final data = node.getSemanticsData();
  final flags = data.flagsCollection;
  if (flags.isHidden) {
    return;
  }

  final canTap = data.hasAction(.tap);
  final roles = <String>[
    if (flags.isHeader) 'heading',
    if (flags.isButton) 'button',
    if (flags.isLink) 'link',
    if (flags.isTextField) 'edit box',
    if (flags.isImage) 'image',
    if (flags.isSlider) 'slider',
    if (flags.isInMutuallyExclusiveGroup) 'radio',
    if (flags.isToggled != .none)
      'switch ${flags.isToggled == .isTrue ? 'on' : 'off'}',
    if (flags.isChecked != .none)
      'checkbox ${flags.isChecked == .isTrue ? 'checked' : 'not checked'}',
    if (flags.isSelected == .isTrue) 'selected',
    if (flags.isExpanded != .none)
      flags.isExpanded == .isTrue ? 'expanded' : 'collapsed',
    if (flags.isEnabled == .isFalse) 'disabled',
    if (flags.isLiveRegion) 'LIVE',
    if (flags.scopesRoute) 'route',
    if (flags.namesRoute) 'names route',
    if (!flags.isButton && !flags.isLink && canTap) 'tappable',
    if (data.hasAction(.longPress)) 'long-press',
    if (data.hasAction(.scrollUp) || data.hasAction(.scrollDown)) 'scrolls',
    if (data.hasAction(.scrollLeft) || data.hasAction(.scrollRight))
      'scrolls sideways',
    if (data.customSemanticsActionIds?.isNotEmpty ?? false)
      '${data.customSemanticsActionIds!.length} actions',
  ];
  final speaks =
      data.label.isNotEmpty ||
      data.value.isNotEmpty ||
      data.hint.isNotEmpty ||
      data.tooltip.isNotEmpty;
  if (speaks || canTap || flags.isTextField || flags.isToggled != .none) {
    final rect = MatrixUtils.transformRect(transform, node.rect);
    final problems = <String>[
      if (canTap && (rect.width < 47.5 || rect.height < 47.5)) 'SMALL',
      if ('\n'.allMatches(data.label).length + 1 >= _blobLines) 'BLOB',
      if (flags.isTextField && data.label.isEmpty) 'NO NAME',
      if (canTap && data.label.isEmpty && data.tooltip.isEmpty) 'NO NAME',
    ];
    String quoted(String text) => text.replaceAll('\n', ' / ');
    lines.add(
      [
        '${'  ' * depth}- ',
        if (roles.isNotEmpty) '[${roles.join(', ')}] ',
        '"${quoted(data.label)}"',
        if (data.value.isNotEmpty) ' value="${quoted(data.value)}"',
        if (data.hint.isNotEmpty) ' hint="${quoted(data.hint)}"',
        if (data.tooltip.isNotEmpty) ' tooltip="${quoted(data.tooltip)}"',
        ' ${rect.width.round()}x${rect.height.round()}',
        if (problems.isNotEmpty) '  <-- ${problems.join(', ')}',
      ].join(),
    );
  }

  final children = node.debugListChildrenInOrder(.traversalOrder);
  for (final child in children) {
    final childTransform = Matrix4.copy(transform);
    _visit(child, depth + 1, lines, childTransform);
  }
}
