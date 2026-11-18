// This is a generated file - do not edit.
//
// Generated from ferret/messages/v1/messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Where a message sits on the phone.
class MessageKind extends $pb.ProtobufEnum {
  static const MessageKind MESSAGE_KIND_UNSPECIFIED =
      MessageKind._(0, _omitEnumNames ? '' : 'MESSAGE_KIND_UNSPECIFIED');

  /// Received.
  static const MessageKind MESSAGE_KIND_INBOX =
      MessageKind._(1, _omitEnumNames ? '' : 'MESSAGE_KIND_INBOX');
  static const MessageKind MESSAGE_KIND_SENT =
      MessageKind._(2, _omitEnumNames ? '' : 'MESSAGE_KIND_SENT');

  /// Being sent right now.
  static const MessageKind MESSAGE_KIND_OUTBOX =
      MessageKind._(3, _omitEnumNames ? '' : 'MESSAGE_KIND_OUTBOX');
  static const MessageKind MESSAGE_KIND_FAILED =
      MessageKind._(4, _omitEnumNames ? '' : 'MESSAGE_KIND_FAILED');

  /// Waiting to be sent, such as with no signal.
  static const MessageKind MESSAGE_KIND_QUEUED =
      MessageKind._(5, _omitEnumNames ? '' : 'MESSAGE_KIND_QUEUED');

  static const $core.List<MessageKind> values = <MessageKind>[
    MESSAGE_KIND_UNSPECIFIED,
    MESSAGE_KIND_INBOX,
    MESSAGE_KIND_SENT,
    MESSAGE_KIND_OUTBOX,
    MESSAGE_KIND_FAILED,
    MESSAGE_KIND_QUEUED,
  ];

  static final $core.List<MessageKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static MessageKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MessageKind._(super.value, super.name);
}

/// Why a message wasn't sent.
class SendFailure extends $pb.ProtobufEnum {
  static const SendFailure SEND_FAILURE_UNSPECIFIED =
      SendFailure._(0, _omitEnumNames ? '' : 'SEND_FAILURE_UNSPECIFIED');

  /// Ferret may not send SMS on the phone.
  static const SendFailure SEND_FAILURE_NO_ACCESS =
      SendFailure._(1, _omitEnumNames ? '' : 'SEND_FAILURE_NO_ACCESS');

  /// No address to send to, or the conversation is gone.
  static const SendFailure SEND_FAILURE_NO_RECIPIENT =
      SendFailure._(2, _omitEnumNames ? '' : 'SEND_FAILURE_NO_RECIPIENT');

  /// Group conversations need MMS, which only the default messaging app sends.
  static const SendFailure SEND_FAILURE_GROUP =
      SendFailure._(3, _omitEnumNames ? '' : 'SEND_FAILURE_GROUP');

  /// The phone has no signal or the carrier refused it.
  static const SendFailure SEND_FAILURE_NO_SERVICE =
      SendFailure._(4, _omitEnumNames ? '' : 'SEND_FAILURE_NO_SERVICE');

  /// The radio didn't confirm in time.
  static const SendFailure SEND_FAILURE_TIMEOUT =
      SendFailure._(5, _omitEnumNames ? '' : 'SEND_FAILURE_TIMEOUT');
  static const SendFailure SEND_FAILURE_OTHER =
      SendFailure._(6, _omitEnumNames ? '' : 'SEND_FAILURE_OTHER');

  static const $core.List<SendFailure> values = <SendFailure>[
    SEND_FAILURE_UNSPECIFIED,
    SEND_FAILURE_NO_ACCESS,
    SEND_FAILURE_NO_RECIPIENT,
    SEND_FAILURE_GROUP,
    SEND_FAILURE_NO_SERVICE,
    SEND_FAILURE_TIMEOUT,
    SEND_FAILURE_OTHER,
  ];

  static final $core.List<SendFailure?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static SendFailure? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SendFailure._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
