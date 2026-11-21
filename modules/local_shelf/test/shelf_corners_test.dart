import 'package:flutter_test/flutter_test.dart';
import 'package:local_shelf/local_shelf.dart';

void main() {
  test('the box, its tiles and their thumbnails are concentric with the '
      'popover\'s corner, each at its gap', () {
    expect(ShelfCorners.window, 20);
    expect(ShelfCorners.box, ShelfCorners.window - ShelfCorners.boxInset);
    expect(ShelfCorners.tile, ShelfCorners.box - ShelfCorners.tileInset);
    expect(ShelfCorners.thumb, ShelfCorners.tile - ShelfCorners.thumbInset);
    expect(ShelfCorners.thumb, greaterThanOrEqualTo(4));
    expect(ShelfBoxFrame.radius, ShelfCorners.box);
    expect(ShelfTile.radius, ShelfCorners.tile);
    expect(ShelfTile.thumbRadius, ShelfCorners.thumb);
    expect(ShelfPanelFrame.radius, ShelfCorners.window);
  });
}
