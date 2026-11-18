import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/remote_input.dart';

void main() {
  test('every wire key has a platform-neutral key, and back', () {
    for (final wire in Key.values) {
      if (wire == Key.KEY_UNSPECIFIED) {
        continue;
      }

      final key = InputCodec.keys[wire];
      expect(key, isNotNull, reason: wire.name);
      if (key == null) {
        continue;
      }

      expect(InputCodec.key(key, pressed: true).key.key, wire);
    }

    expect(InputCodec.keys, hasLength(InputKey.values.length));
  });

  test('a key event keeps its modifiers in order', () {
    final event = InputCodec.key(
      .c,
      pressed: true,
      modifiers: {.meta, .shift},
    );

    expect(event.key.key, Key.KEY_C);
    expect(event.key.modifiers, [
      Modifier.MODIFIER_SHIFT,
      Modifier.MODIFIER_META,
    ]);
    expect(
      InputCodec.actionOf(event),
      const KeyAction(.c, pressed: true, modifiers: {.shift, .meta}),
    );
  });

  test('a batch becomes actions in order', () {
    final batch = InputBatch(
      events: [
        InputCodec.move(3, -2),
        InputCodec.button(.left, pressed: true),
        InputCodec.scroll(0, 40),
        InputCodec.text('hi'),
        InputCodec.key(.arrowLeft, pressed: false),
      ],
    );

    expect(InputCodec.actionsOf(batch), const [
      MoveAction(3, -2),
      ButtonAction(.left, pressed: true),
      ScrollAction(0, 40),
      TextAction('hi'),
      KeyAction(.arrowLeft, pressed: false),
    ]);
  });

  test('unknown and empty events are skipped', () {
    final batch = InputBatch(
      events: [
        InputEvent(),
        InputEvent(key: KeyEvent(key: Key.KEY_UNSPECIFIED)),
        InputEvent(button: ButtonEvent()),
        InputCodec.text(''),
      ],
    );

    expect(InputCodec.actionsOf(batch), isEmpty);
  });

  test('huge moves and long text are cut to sane bounds', () {
    final batch = InputBatch(
      events: [
        InputCodec.move(1 << 30, -(1 << 30)),
        InputCodec.text('a' * (InputCodec.maxTextLength + 10)),
      ],
    );

    final actions = InputCodec.actionsOf(batch);

    expect(actions.first, const MoveAction(10000, -10000));
    expect(
      (actions.last as TextAction).text,
      hasLength(InputCodec.maxTextLength),
    );
  });

  test('a batch is capped', () {
    final batch = InputBatch(
      events: [
        for (var index = 0; index < InputCodec.maxEventsPerBatch + 5; index++)
          InputCodec.move(1, 0),
      ],
    );

    expect(
      InputCodec.actionsOf(batch),
      hasLength(InputCodec.maxEventsPerBatch),
    );
  });
}
