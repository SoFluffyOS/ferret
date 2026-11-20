import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';

class _Sink implements InputSink {
  final List<Object> got = [];

  List<InputAction> get actions => [
    for (final item in got)
      if (item case final InputEvent event) ?InputCodec.actionOf(event),
  ];

  @override
  void move(double dx, double dy) => got.add(('move', dx, dy));

  @override
  void scroll(double dx, double dy) => got.add(('scroll', dx, dy));

  @override
  void add(InputEvent event) => got.add(event);
}

const _shift = 1;
const _control = 2;
const _option = 4;
const _command = 8;
const _keyC = 0x08;
const _keyA = 0x00;
const _arrowLeft = 0x7B;

void main() {
  test('moves and buttons go as they are, scrolls the wire way round', () {
    final sink = _Sink();
    CaptureTranslator()
      ..translate(captured(.move, x: 3.5, y: -2), sink)
      ..translate(captured(.scroll, x: 1, y: 12), sink)
      ..translate(captured(.button, code: 1, pressed: true), sink)
      ..translate(captured(.button, code: 7, pressed: true), sink);

    expect(sink.got.take(2), [('move', 3.5, -2.0), ('scroll', -1.0, -12.0)]);
    expect(sink.actions, const [ButtonAction(.right, pressed: true)]);
  });

  test('typing goes as text, whatever the layout says it typed', () {
    final sink = _Sink();
    CaptureTranslator()
      ..translate(
        captured(
          .key,
          code: _keyA,
          pressed: true,
          modifiers: _shift,
          text: 'A',
        ),
        sink,
      )
      ..translate(captured(.key, code: _keyA, text: 'A'), sink)
      ..translate(captured(.key, code: 0x2B, pressed: true, text: ','), sink);

    expect(sink.actions, const [TextAction('A'), TextAction(',')]);
  });

  test('keys that type nothing go as keys, with Shift', () {
    final sink = _Sink();
    CaptureTranslator()
      ..translate(
        captured(
          .key,
          code: _arrowLeft,
          pressed: true,
          modifiers: _shift,
          text: '',
        ),
        sink,
      )
      ..translate(captured(.key, code: _arrowLeft), sink)
      ..translate(
        captured(.key, code: 0x4C, pressed: true, text: '\u0003'),
        sink,
      );

    expect(sink.actions, const [
      KeyAction(.arrowLeft, pressed: true, modifiers: {.shift}),
      KeyAction(.arrowLeft, pressed: false, modifiers: {.shift}),
      KeyAction(.enter, pressed: true),
    ]);
  });

  test('on a PC, ⌘C is Ctrl+C and ⌃ is the Windows key', () {
    final sink = _Sink();
    CaptureTranslator(swapCommandAndControl: true)
      ..translate(captured(.modifiers, modifiers: _command), sink)
      ..translate(
        captured(.key, code: _keyC, pressed: true, modifiers: _command),
        sink,
      )
      ..translate(captured(.key, code: _keyC, modifiers: _command), sink)
      ..translate(captured(.modifiers, modifiers: _control), sink);

    expect(sink.actions, const [
      ModifiersAction({.control}),
      KeyAction(.c, pressed: true, modifiers: {.control}),
      KeyAction(.c, pressed: false, modifiers: {.control}),
      ModifiersAction({.meta}),
    ]);
  });

  test('on a Mac, ⌘ stays ⌘', () {
    final sink = _Sink();
    CaptureTranslator().translate(
      captured(.key, code: _keyC, pressed: true, modifiers: _command),
      sink,
    );

    expect(sink.actions, const [
      KeyAction(.c, pressed: true, modifiers: {.meta}),
    ]);
  });

  test('entering leaves out the switch keys, and their release sends '
      'nothing', () {
    final sink = _Sink();
    final translator = CaptureTranslator();

    expect(translator.enter({.control, .alt, .shift}), {KeyModifier.shift});
    translator
      ..translate(captured(.modifiers, modifiers: _shift), sink)
      ..translate(captured(.modifiers, modifiers: _shift | _option), sink);

    expect(sink.actions, const [
      ModifiersAction({.shift, .alt}),
    ]);
  });

  test('a key up with no key down sends nothing', () {
    final sink = _Sink();
    CaptureTranslator().translate(captured(.key, code: _keyC), sink);

    expect(sink.got, isEmpty);
  });
}
