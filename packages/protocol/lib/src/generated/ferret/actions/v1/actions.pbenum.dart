// This is a generated file - do not edit.
//
// Generated from ferret/actions/v1/actions.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// What an action does on the computer that offers it.
class ActionKind extends $pb.ProtobufEnum {
  static const ActionKind ACTION_KIND_UNSPECIFIED =
      ActionKind._(0, _omitEnumNames ? '' : 'ACTION_KIND_UNSPECIFIED');

  /// Puts the computer to sleep.
  static const ActionKind ACTION_KIND_SLEEP =
      ActionKind._(1, _omitEnumNames ? '' : 'ACTION_KIND_SLEEP');

  /// Restarts the computer, after a countdown its owner can cancel.
  static const ActionKind ACTION_KIND_RESTART =
      ActionKind._(2, _omitEnumNames ? '' : 'ACTION_KIND_RESTART');

  /// Turns the computer off, after a countdown its owner can cancel.
  static const ActionKind ACTION_KIND_SHUT_DOWN =
      ActionKind._(3, _omitEnumNames ? '' : 'ACTION_KIND_SHUT_DOWN');

  /// Mutes the sound, or brings it back when it is muted.
  static const ActionKind ACTION_KIND_MUTE =
      ActionKind._(4, _omitEnumNames ? '' : 'ACTION_KIND_MUTE');
  static const ActionKind ACTION_KIND_VOLUME_UP =
      ActionKind._(5, _omitEnumNames ? '' : 'ACTION_KIND_VOLUME_UP');
  static const ActionKind ACTION_KIND_VOLUME_DOWN =
      ActionKind._(6, _omitEnumNames ? '' : 'ACTION_KIND_VOLUME_DOWN');

  /// A command its owner defined on the computer. The command line never
  /// leaves that computer: only `id` and `title` do.
  static const ActionKind ACTION_KIND_CUSTOM =
      ActionKind._(7, _omitEnumNames ? '' : 'ACTION_KIND_CUSTOM');

  static const $core.List<ActionKind> values = <ActionKind>[
    ACTION_KIND_UNSPECIFIED,
    ACTION_KIND_SLEEP,
    ACTION_KIND_RESTART,
    ACTION_KIND_SHUT_DOWN,
    ACTION_KIND_MUTE,
    ACTION_KIND_VOLUME_UP,
    ACTION_KIND_VOLUME_DOWN,
    ACTION_KIND_CUSTOM,
  ];

  static final $core.List<ActionKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 7);
  static ActionKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ActionKind._(super.value, super.name);
}

/// How a `RunAction` went.
class RunResult extends $pb.ProtobufEnum {
  static const RunResult RUN_RESULT_UNSPECIFIED =
      RunResult._(0, _omitEnumNames ? '' : 'RUN_RESULT_UNSPECIFIED');

  /// It ran. For sleep, restart and shut down: it is about to.
  static const RunResult RUN_RESULT_DONE =
      RunResult._(1, _omitEnumNames ? '' : 'RUN_RESULT_DONE');

  /// The owner said no on the computer.
  static const RunResult RUN_RESULT_DENIED =
      RunResult._(2, _omitEnumNames ? '' : 'RUN_RESULT_DENIED');

  /// Nobody answered the question on the computer in time.
  static const RunResult RUN_RESULT_NOT_ANSWERED =
      RunResult._(3, _omitEnumNames ? '' : 'RUN_RESULT_NOT_ANSWERED');

  /// The computer is asking about, or counting down, another request.
  static const RunResult RUN_RESULT_BUSY =
      RunResult._(4, _omitEnumNames ? '' : 'RUN_RESULT_BUSY');

  /// Actions are turned off on the computer.
  static const RunResult RUN_RESULT_TURNED_OFF =
      RunResult._(5, _omitEnumNames ? '' : 'RUN_RESULT_TURNED_OFF');

  /// No action has that id, such as one its owner removed.
  static const RunResult RUN_RESULT_UNKNOWN_ACTION =
      RunResult._(6, _omitEnumNames ? '' : 'RUN_RESULT_UNKNOWN_ACTION');

  /// It was tried and didn't work. For a custom action: it couldn't start,
  /// or ended with a non-zero `exit_code`.
  static const RunResult RUN_RESULT_FAILED =
      RunResult._(7, _omitEnumNames ? '' : 'RUN_RESULT_FAILED');

  /// Someone cancelled the countdown on the computer.
  static const RunResult RUN_RESULT_CANCELLED =
      RunResult._(8, _omitEnumNames ? '' : 'RUN_RESULT_CANCELLED');

  /// A custom action ran longer than the computer allows and was stopped.
  static const RunResult RUN_RESULT_TIMED_OUT =
      RunResult._(9, _omitEnumNames ? '' : 'RUN_RESULT_TIMED_OUT');

  static const $core.List<RunResult> values = <RunResult>[
    RUN_RESULT_UNSPECIFIED,
    RUN_RESULT_DONE,
    RUN_RESULT_DENIED,
    RUN_RESULT_NOT_ANSWERED,
    RUN_RESULT_BUSY,
    RUN_RESULT_TURNED_OFF,
    RUN_RESULT_UNKNOWN_ACTION,
    RUN_RESULT_FAILED,
    RUN_RESULT_CANCELLED,
    RUN_RESULT_TIMED_OUT,
  ];

  static final $core.List<RunResult?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 9);
  static RunResult? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const RunResult._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
