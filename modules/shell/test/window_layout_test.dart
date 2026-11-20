import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/window_layout.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

void main() {
  double contentBeside(double width, double scale) =>
      width -
      WindowLayout.sidebarWidth(
        ScreenSize.fromWidth(width),
        textScaler: TextScaler.linear(scale),
      );

  bool fits(double width, double scale) => WindowLayout.activityPaneFits(
    width: contentBeside(width, scale),
    textScale: scale,
  );

  test('at 100% text the pane shows from 1200 dp, as before', () {
    expect(fits(1200, 1), isTrue);
    expect(fits(1280, 1), isTrue);
  });

  test('a 1280 dp landscape tablet folds the pane away at large text', () {
    expect(fits(1280, 1.3), isFalse);
    expect(fits(1280, 2), isFalse);
  });

  test('a window wide enough for the text keeps the pane', () {
    expect(fits(1440, 1.3), isTrue);
    expect(fits(1920, 2), isTrue);
    expect(fits(1600, 2), isFalse);
  });

  test('hiding the device list gives the room back', () {
    expect(
      WindowLayout.activityPaneFits(width: 1280, textScale: 1.3),
      isTrue,
    );
  });
}
