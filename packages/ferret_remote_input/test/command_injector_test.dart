import 'dart:async';
import 'dart:io';

import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('neighbouring moves and scrolls are merged', () {
    expect(
      CommandInjector.merge(const [
        MoveAction(1, 2),
        MoveAction(3, 4),
        ButtonAction(.left, pressed: true),
        ScrollAction(0, 5),
        ScrollAction(1, 5),
      ]),
      const [
        MoveAction(4, 6),
        ButtonAction(.left, pressed: true),
        ScrollAction(1, 10),
      ],
    );
  });

  group('xdotool', () {
    test('chains a batch into one run, and text ends a run', () {
      final injector = CommandInjector(.xdotool);

      final commands = injector.commandsOf(const [
        MoveAction(-5, 3),
        ButtonAction(.right, pressed: true),
        ButtonAction(.right, pressed: false),
        KeyAction(.c, pressed: true, modifiers: {.control}),
        KeyAction(.c, pressed: false),
        TextAction('hi there'),
        KeyAction(.enter, pressed: true),
      ]);

      expect(commands, [
        [
          'mousemove_relative',
          '--',
          '-5',
          '3',
          'mousedown',
          '3',
          'mouseup',
          '3',
          'keydown',
          'ctrl+c',
          'keyup',
          'ctrl+c',
          'type',
          '--delay',
          '0',
          '--',
          'hi there',
        ],
        ['keydown', 'Return'],
      ]);
    });

    test('scrolls by whole notches and keeps the rest', () {
      final injector = CommandInjector(.xdotool);

      expect(injector.commandsOf(const [ScrollAction(0, 30)]), isEmpty);
      expect(injector.commandsOf(const [ScrollAction(0, 55)]), [
        ['click', '--repeat', '2', '--delay', '1', '5'],
      ]);
      expect(injector.commandsOf(const [ScrollAction(-40, -45)]), [
        [
          'click',
          '--repeat',
          '1',
          '--delay',
          '1',
          '4',
          'click',
          '--repeat',
          '1',
          '--delay',
          '1',
          '6',
        ],
      ]);
    });
  });

  group('ydotool', () {
    test('runs one command per action, with raw key codes', () {
      final injector = CommandInjector(.ydotool);

      final commands = injector.commandsOf(const [
        MoveAction(2, -1),
        ButtonAction(.left, pressed: true),
        ButtonAction(.left, pressed: false),
        KeyAction(.a, pressed: true, modifiers: {.shift}),
        KeyAction(.a, pressed: false),
        ScrollAction(0, 80),
        TextAction('ok'),
      ]);

      expect(commands, [
        ['mousemove', '-x', '2', '-y', '-1'],
        ['click', '0x40'],
        ['click', '0x80'],
        ['key', '42:1', '30:1', '30:0', '42:0'],
        ['mousemove', '-w', '-x', '0', '-y', '-2'],
        ['type', '--', 'ok'],
      ]);
    });
  });

  test('runs commands one at a time and merges what piles up', () async {
    final runs = <List<String>>[];
    final gate = Completer<void>();
    final injector = CommandInjector(
      .xdotool,
      run: (executable, arguments) async {
        runs.add(arguments);
        if (runs.length == 1) {
          await gate.future;
        }

        return ProcessResult(0, 0, '', '');
      },
    );

    final first = injector.inject(const [MoveAction(1, 1)]);
    unawaited(injector.inject(const [MoveAction(2, 2)]));
    final last = injector.inject(const [MoveAction(3, 3)]);
    gate.complete();
    await first;
    await last;

    expect(runs, [
      ['mousemove_relative', '--', '1', '1'],
      ['mousemove_relative', '--', '5', '5'],
    ]);
    expect(injector.failing, isFalse);
  });

  test('a failing tool is noted', () async {
    final injector = CommandInjector(
      .ydotool,
      run: (_, _) async => throw const ProcessException('ydotool', []),
    );

    await injector.inject(const [MoveAction(1, 1)]);

    expect(injector.failing, isTrue);
  });
}
