import 'package:flutter_test/flutter_test.dart';
import 'package:updates/updates.dart';

void main() {
  test('reads Markdown notes as plain lines', () {
    final lines = ReleaseNotesText.linesOf(
      '## New\n\n- **Updates**: see [the docs](https://x.y)\n* `ferret-cli` too\nPlain line\n',
    );

    expect(lines.map((line) => line.text), [
      'New',
      'Updates: see the docs',
      'ferret-cli too',
      'Plain line',
    ]);
    expect(lines.map((line) => line.isHeading), [true, false, false, false]);
    expect(lines.map((line) => line.isBullet), [false, true, true, false]);
  });
}
