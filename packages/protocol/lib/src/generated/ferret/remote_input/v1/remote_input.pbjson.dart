// This is a generated file - do not edit.
//
// Generated from ferret/remote_input/v1/remote_input.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use controlModeDescriptor instead')
const ControlMode$json = {
  '1': 'ControlMode',
  '2': [
    {'1': 'CONTROL_MODE_UNSPECIFIED', '2': 0},
    {'1': 'CONTROL_MODE_SCREEN', '2': 1},
  ],
};

/// Descriptor for `ControlMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List controlModeDescriptor = $convert.base64Decode(
    'CgtDb250cm9sTW9kZRIcChhDT05UUk9MX01PREVfVU5TUEVDSUZJRUQQABIXChNDT05UUk9MX0'
    '1PREVfU0NSRUVOEAE=');

@$core.Deprecated('Use denyReasonDescriptor instead')
const DenyReason$json = {
  '1': 'DenyReason',
  '2': [
    {'1': 'DENY_REASON_UNSPECIFIED', '2': 0},
    {'1': 'DENY_REASON_DENIED', '2': 1},
    {'1': 'DENY_REASON_TIMEOUT', '2': 2},
    {'1': 'DENY_REASON_BUSY', '2': 3},
    {'1': 'DENY_REASON_NEEDS_PERMISSION', '2': 4},
    {'1': 'DENY_REASON_UNSUPPORTED', '2': 5},
    {'1': 'DENY_REASON_TURNED_OFF', '2': 6},
    {'1': 'DENY_REASON_VERSION', '2': 7},
  ],
};

/// Descriptor for `DenyReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List denyReasonDescriptor = $convert.base64Decode(
    'CgpEZW55UmVhc29uEhsKF0RFTllfUkVBU09OX1VOU1BFQ0lGSUVEEAASFgoSREVOWV9SRUFTT0'
    '5fREVOSUVEEAESFwoTREVOWV9SRUFTT05fVElNRU9VVBACEhQKEERFTllfUkVBU09OX0JVU1kQ'
    'AxIgChxERU5ZX1JFQVNPTl9ORUVEU19QRVJNSVNTSU9OEAQSGwoXREVOWV9SRUFTT05fVU5TVV'
    'BQT1JURUQQBRIaChZERU5ZX1JFQVNPTl9UVVJORURfT0ZGEAYSFwoTREVOWV9SRUFTT05fVkVS'
    'U0lPThAH');

@$core.Deprecated('Use stopReasonDescriptor instead')
const StopReason$json = {
  '1': 'StopReason',
  '2': [
    {'1': 'STOP_REASON_UNSPECIFIED', '2': 0},
    {'1': 'STOP_REASON_CONTROLLER_DONE', '2': 1},
    {'1': 'STOP_REASON_STOPPED_ON_HOST', '2': 2},
    {'1': 'STOP_REASON_IDLE', '2': 3},
    {'1': 'STOP_REASON_REVOKED', '2': 4},
    {'1': 'STOP_REASON_NOT_CONTROLLING', '2': 5},
    {'1': 'STOP_REASON_FAILED', '2': 6},
  ],
};

/// Descriptor for `StopReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List stopReasonDescriptor = $convert.base64Decode(
    'CgpTdG9wUmVhc29uEhsKF1NUT1BfUkVBU09OX1VOU1BFQ0lGSUVEEAASHwobU1RPUF9SRUFTT0'
    '5fQ09OVFJPTExFUl9ET05FEAESHwobU1RPUF9SRUFTT05fU1RPUFBFRF9PTl9IT1NUEAISFAoQ'
    'U1RPUF9SRUFTT05fSURMRRADEhcKE1NUT1BfUkVBU09OX1JFVk9LRUQQBBIfChtTVE9QX1JFQV'
    'NPTl9OT1RfQ09OVFJPTExJTkcQBRIWChJTVE9QX1JFQVNPTl9GQUlMRUQQBg==');

@$core.Deprecated('Use mouseButtonDescriptor instead')
const MouseButton$json = {
  '1': 'MouseButton',
  '2': [
    {'1': 'MOUSE_BUTTON_UNSPECIFIED', '2': 0},
    {'1': 'MOUSE_BUTTON_LEFT', '2': 1},
    {'1': 'MOUSE_BUTTON_RIGHT', '2': 2},
    {'1': 'MOUSE_BUTTON_MIDDLE', '2': 3},
  ],
};

/// Descriptor for `MouseButton`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List mouseButtonDescriptor = $convert.base64Decode(
    'CgtNb3VzZUJ1dHRvbhIcChhNT1VTRV9CVVRUT05fVU5TUEVDSUZJRUQQABIVChFNT1VTRV9CVV'
    'RUT05fTEVGVBABEhYKEk1PVVNFX0JVVFRPTl9SSUdIVBACEhcKE01PVVNFX0JVVFRPTl9NSURE'
    'TEUQAw==');

@$core.Deprecated('Use keyDescriptor instead')
const Key$json = {
  '1': 'Key',
  '2': [
    {'1': 'KEY_UNSPECIFIED', '2': 0},
    {'1': 'KEY_ENTER', '2': 1},
    {'1': 'KEY_BACKSPACE', '2': 2},
    {'1': 'KEY_DELETE', '2': 3},
    {'1': 'KEY_TAB', '2': 4},
    {'1': 'KEY_ESCAPE', '2': 5},
    {'1': 'KEY_SPACE', '2': 6},
    {'1': 'KEY_ARROW_LEFT', '2': 7},
    {'1': 'KEY_ARROW_RIGHT', '2': 8},
    {'1': 'KEY_ARROW_UP', '2': 9},
    {'1': 'KEY_ARROW_DOWN', '2': 10},
    {'1': 'KEY_HOME', '2': 11},
    {'1': 'KEY_END', '2': 12},
    {'1': 'KEY_PAGE_UP', '2': 13},
    {'1': 'KEY_PAGE_DOWN', '2': 14},
    {'1': 'KEY_MEDIA_PLAY_PAUSE', '2': 20},
    {'1': 'KEY_MEDIA_NEXT', '2': 21},
    {'1': 'KEY_MEDIA_PREVIOUS', '2': 22},
    {'1': 'KEY_VOLUME_UP', '2': 23},
    {'1': 'KEY_VOLUME_DOWN', '2': 24},
    {'1': 'KEY_VOLUME_MUTE', '2': 25},
    {'1': 'KEY_F1', '2': 31},
    {'1': 'KEY_F2', '2': 32},
    {'1': 'KEY_F3', '2': 33},
    {'1': 'KEY_F4', '2': 34},
    {'1': 'KEY_F5', '2': 35},
    {'1': 'KEY_F6', '2': 36},
    {'1': 'KEY_F7', '2': 37},
    {'1': 'KEY_F8', '2': 38},
    {'1': 'KEY_F9', '2': 39},
    {'1': 'KEY_F10', '2': 40},
    {'1': 'KEY_F11', '2': 41},
    {'1': 'KEY_F12', '2': 42},
    {'1': 'KEY_A', '2': 65},
    {'1': 'KEY_B', '2': 66},
    {'1': 'KEY_C', '2': 67},
    {'1': 'KEY_D', '2': 68},
    {'1': 'KEY_E', '2': 69},
    {'1': 'KEY_F', '2': 70},
    {'1': 'KEY_G', '2': 71},
    {'1': 'KEY_H', '2': 72},
    {'1': 'KEY_I', '2': 73},
    {'1': 'KEY_J', '2': 74},
    {'1': 'KEY_K', '2': 75},
    {'1': 'KEY_L', '2': 76},
    {'1': 'KEY_M', '2': 77},
    {'1': 'KEY_N', '2': 78},
    {'1': 'KEY_O', '2': 79},
    {'1': 'KEY_P', '2': 80},
    {'1': 'KEY_Q', '2': 81},
    {'1': 'KEY_R', '2': 82},
    {'1': 'KEY_S', '2': 83},
    {'1': 'KEY_T', '2': 84},
    {'1': 'KEY_U', '2': 85},
    {'1': 'KEY_V', '2': 86},
    {'1': 'KEY_W', '2': 87},
    {'1': 'KEY_X', '2': 88},
    {'1': 'KEY_Y', '2': 89},
    {'1': 'KEY_Z', '2': 90},
    {'1': 'KEY_DIGIT_0', '2': 100},
    {'1': 'KEY_DIGIT_1', '2': 101},
    {'1': 'KEY_DIGIT_2', '2': 102},
    {'1': 'KEY_DIGIT_3', '2': 103},
    {'1': 'KEY_DIGIT_4', '2': 104},
    {'1': 'KEY_DIGIT_5', '2': 105},
    {'1': 'KEY_DIGIT_6', '2': 106},
    {'1': 'KEY_DIGIT_7', '2': 107},
    {'1': 'KEY_DIGIT_8', '2': 108},
    {'1': 'KEY_DIGIT_9', '2': 109},
  ],
};

/// Descriptor for `Key`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List keyDescriptor = $convert.base64Decode(
    'CgNLZXkSEwoPS0VZX1VOU1BFQ0lGSUVEEAASDQoJS0VZX0VOVEVSEAESEQoNS0VZX0JBQ0tTUE'
    'FDRRACEg4KCktFWV9ERUxFVEUQAxILCgdLRVlfVEFCEAQSDgoKS0VZX0VTQ0FQRRAFEg0KCUtF'
    'WV9TUEFDRRAGEhIKDktFWV9BUlJPV19MRUZUEAcSEwoPS0VZX0FSUk9XX1JJR0hUEAgSEAoMS0'
    'VZX0FSUk9XX1VQEAkSEgoOS0VZX0FSUk9XX0RPV04QChIMCghLRVlfSE9NRRALEgsKB0tFWV9F'
    'TkQQDBIPCgtLRVlfUEFHRV9VUBANEhEKDUtFWV9QQUdFX0RPV04QDhIYChRLRVlfTUVESUFfUE'
    'xBWV9QQVVTRRAUEhIKDktFWV9NRURJQV9ORVhUEBUSFgoSS0VZX01FRElBX1BSRVZJT1VTEBYS'
    'EQoNS0VZX1ZPTFVNRV9VUBAXEhMKD0tFWV9WT0xVTUVfRE9XThAYEhMKD0tFWV9WT0xVTUVfTV'
    'VURRAZEgoKBktFWV9GMRAfEgoKBktFWV9GMhAgEgoKBktFWV9GMxAhEgoKBktFWV9GNBAiEgoK'
    'BktFWV9GNRAjEgoKBktFWV9GNhAkEgoKBktFWV9GNxAlEgoKBktFWV9GOBAmEgoKBktFWV9GOR'
    'AnEgsKB0tFWV9GMTAQKBILCgdLRVlfRjExECkSCwoHS0VZX0YxMhAqEgkKBUtFWV9BEEESCQoF'
    'S0VZX0IQQhIJCgVLRVlfQxBDEgkKBUtFWV9EEEQSCQoFS0VZX0UQRRIJCgVLRVlfRhBGEgkKBU'
    'tFWV9HEEcSCQoFS0VZX0gQSBIJCgVLRVlfSRBJEgkKBUtFWV9KEEoSCQoFS0VZX0sQSxIJCgVL'
    'RVlfTBBMEgkKBUtFWV9NEE0SCQoFS0VZX04QThIJCgVLRVlfTxBPEgkKBUtFWV9QEFASCQoFS0'
    'VZX1EQURIJCgVLRVlfUhBSEgkKBUtFWV9TEFMSCQoFS0VZX1QQVBIJCgVLRVlfVRBVEgkKBUtF'
    'WV9WEFYSCQoFS0VZX1cQVxIJCgVLRVlfWBBYEgkKBUtFWV9ZEFkSCQoFS0VZX1oQWhIPCgtLRV'
    'lfRElHSVRfMBBkEg8KC0tFWV9ESUdJVF8xEGUSDwoLS0VZX0RJR0lUXzIQZhIPCgtLRVlfRElH'
    'SVRfMxBnEg8KC0tFWV9ESUdJVF80EGgSDwoLS0VZX0RJR0lUXzUQaRIPCgtLRVlfRElHSVRfNh'
    'BqEg8KC0tFWV9ESUdJVF83EGsSDwoLS0VZX0RJR0lUXzgQbBIPCgtLRVlfRElHSVRfORBt');

@$core.Deprecated('Use modifierDescriptor instead')
const Modifier$json = {
  '1': 'Modifier',
  '2': [
    {'1': 'MODIFIER_UNSPECIFIED', '2': 0},
    {'1': 'MODIFIER_SHIFT', '2': 1},
    {'1': 'MODIFIER_CONTROL', '2': 2},
    {'1': 'MODIFIER_ALT', '2': 3},
    {'1': 'MODIFIER_META', '2': 4},
  ],
};

/// Descriptor for `Modifier`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List modifierDescriptor = $convert.base64Decode(
    'CghNb2RpZmllchIYChRNT0RJRklFUl9VTlNQRUNJRklFRBAAEhIKDk1PRElGSUVSX1NISUZUEA'
    'ESFAoQTU9ESUZJRVJfQ09OVFJPTBACEhAKDE1PRElGSUVSX0FMVBADEhEKDU1PRElGSUVSX01F'
    'VEEQBA==');

@$core.Deprecated('Use lockResultDescriptor instead')
const LockResult$json = {
  '1': 'LockResult',
  '2': [
    {'1': 'LOCK_RESULT_UNSPECIFIED', '2': 0},
    {'1': 'LOCK_RESULT_LOCKED', '2': 1},
    {'1': 'LOCK_RESULT_DENIED', '2': 2},
    {'1': 'LOCK_RESULT_TIMEOUT', '2': 3},
    {'1': 'LOCK_RESULT_BUSY', '2': 4},
    {'1': 'LOCK_RESULT_TURNED_OFF', '2': 5},
    {'1': 'LOCK_RESULT_FAILED', '2': 6},
  ],
};

/// Descriptor for `LockResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List lockResultDescriptor = $convert.base64Decode(
    'CgpMb2NrUmVzdWx0EhsKF0xPQ0tfUkVTVUxUX1VOU1BFQ0lGSUVEEAASFgoSTE9DS19SRVNVTF'
    'RfTE9DS0VEEAESFgoSTE9DS19SRVNVTFRfREVOSUVEEAISFwoTTE9DS19SRVNVTFRfVElNRU9V'
    'VBADEhQKEExPQ0tfUkVTVUxUX0JVU1kQBBIaChZMT0NLX1JFU1VMVF9UVVJORURfT0ZGEAUSFg'
    'oSTE9DS19SRVNVTFRfRkFJTEVEEAY=');

@$core.Deprecated('Use controlRequestDescriptor instead')
const ControlRequest$json = {
  '1': 'ControlRequest',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 13, '10': 'version'},
    {
      '1': 'mode',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.remote_input.v1.ControlMode',
      '10': 'mode'
    },
  ],
};

/// Descriptor for `ControlRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlRequestDescriptor = $convert.base64Decode(
    'Cg5Db250cm9sUmVxdWVzdBIYCgd2ZXJzaW9uGAEgASgNUgd2ZXJzaW9uEjcKBG1vZGUYAiABKA'
    '4yIy5mZXJyZXQucmVtb3RlX2lucHV0LnYxLkNvbnRyb2xNb2RlUgRtb2Rl');

@$core.Deprecated('Use controlPendingDescriptor instead')
const ControlPending$json = {
  '1': 'ControlPending',
  '2': [
    {'1': 'timeout_seconds', '3': 1, '4': 1, '5': 13, '10': 'timeoutSeconds'},
  ],
};

/// Descriptor for `ControlPending`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlPendingDescriptor = $convert.base64Decode(
    'Cg5Db250cm9sUGVuZGluZxInCg90aW1lb3V0X3NlY29uZHMYASABKA1SDnRpbWVvdXRTZWNvbm'
    'Rz');

@$core.Deprecated('Use controlGrantDescriptor instead')
const ControlGrant$json = {
  '1': 'ControlGrant',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 13, '10': 'version'},
    {'1': 'always', '3': 2, '4': 1, '5': 8, '10': 'always'},
  ],
};

/// Descriptor for `ControlGrant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlGrantDescriptor = $convert.base64Decode(
    'CgxDb250cm9sR3JhbnQSGAoHdmVyc2lvbhgBIAEoDVIHdmVyc2lvbhIWCgZhbHdheXMYAiABKA'
    'hSBmFsd2F5cw==');

@$core.Deprecated('Use controlDenyDescriptor instead')
const ControlDeny$json = {
  '1': 'ControlDeny',
  '2': [
    {
      '1': 'reason',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.remote_input.v1.DenyReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `ControlDeny`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlDenyDescriptor = $convert.base64Decode(
    'CgtDb250cm9sRGVueRI6CgZyZWFzb24YASABKA4yIi5mZXJyZXQucmVtb3RlX2lucHV0LnYxLk'
    'RlbnlSZWFzb25SBnJlYXNvbg==');

@$core.Deprecated('Use controlStopDescriptor instead')
const ControlStop$json = {
  '1': 'ControlStop',
  '2': [
    {
      '1': 'reason',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.remote_input.v1.StopReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `ControlStop`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlStopDescriptor = $convert.base64Decode(
    'CgtDb250cm9sU3RvcBI6CgZyZWFzb24YASABKA4yIi5mZXJyZXQucmVtb3RlX2lucHV0LnYxLl'
    'N0b3BSZWFzb25SBnJlYXNvbg==');

@$core.Deprecated('Use pointerMoveDescriptor instead')
const PointerMove$json = {
  '1': 'PointerMove',
  '2': [
    {'1': 'dx', '3': 1, '4': 1, '5': 17, '10': 'dx'},
    {'1': 'dy', '3': 2, '4': 1, '5': 17, '10': 'dy'},
  ],
};

/// Descriptor for `PointerMove`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pointerMoveDescriptor = $convert.base64Decode(
    'CgtQb2ludGVyTW92ZRIOCgJkeBgBIAEoEVICZHgSDgoCZHkYAiABKBFSAmR5');

@$core.Deprecated('Use buttonEventDescriptor instead')
const ButtonEvent$json = {
  '1': 'ButtonEvent',
  '2': [
    {
      '1': 'button',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.remote_input.v1.MouseButton',
      '10': 'button'
    },
    {'1': 'pressed', '3': 2, '4': 1, '5': 8, '10': 'pressed'},
  ],
};

/// Descriptor for `ButtonEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buttonEventDescriptor = $convert.base64Decode(
    'CgtCdXR0b25FdmVudBI7CgZidXR0b24YASABKA4yIy5mZXJyZXQucmVtb3RlX2lucHV0LnYxLk'
    '1vdXNlQnV0dG9uUgZidXR0b24SGAoHcHJlc3NlZBgCIAEoCFIHcHJlc3NlZA==');

@$core.Deprecated('Use scrollDescriptor instead')
const Scroll$json = {
  '1': 'Scroll',
  '2': [
    {'1': 'dx', '3': 1, '4': 1, '5': 17, '10': 'dx'},
    {'1': 'dy', '3': 2, '4': 1, '5': 17, '10': 'dy'},
  ],
};

/// Descriptor for `Scroll`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scrollDescriptor = $convert
    .base64Decode('CgZTY3JvbGwSDgoCZHgYASABKBFSAmR4Eg4KAmR5GAIgASgRUgJkeQ==');

@$core.Deprecated('Use keyEventDescriptor instead')
const KeyEvent$json = {
  '1': 'KeyEvent',
  '2': [
    {
      '1': 'key',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.remote_input.v1.Key',
      '10': 'key'
    },
    {'1': 'pressed', '3': 2, '4': 1, '5': 8, '10': 'pressed'},
    {
      '1': 'modifiers',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.ferret.remote_input.v1.Modifier',
      '10': 'modifiers'
    },
  ],
};

/// Descriptor for `KeyEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyEventDescriptor = $convert.base64Decode(
    'CghLZXlFdmVudBItCgNrZXkYASABKA4yGy5mZXJyZXQucmVtb3RlX2lucHV0LnYxLktleVIDa2'
    'V5EhgKB3ByZXNzZWQYAiABKAhSB3ByZXNzZWQSPgoJbW9kaWZpZXJzGAMgAygOMiAuZmVycmV0'
    'LnJlbW90ZV9pbnB1dC52MS5Nb2RpZmllclIJbW9kaWZpZXJz');

@$core.Deprecated('Use textInputDescriptor instead')
const TextInput$json = {
  '1': 'TextInput',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `TextInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textInputDescriptor =
    $convert.base64Decode('CglUZXh0SW5wdXQSEgoEdGV4dBgBIAEoCVIEdGV4dA==');

@$core.Deprecated('Use modifierStateDescriptor instead')
const ModifierState$json = {
  '1': 'ModifierState',
  '2': [
    {
      '1': 'held',
      '3': 1,
      '4': 3,
      '5': 14,
      '6': '.ferret.remote_input.v1.Modifier',
      '10': 'held'
    },
  ],
};

/// Descriptor for `ModifierState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List modifierStateDescriptor = $convert.base64Decode(
    'Cg1Nb2RpZmllclN0YXRlEjQKBGhlbGQYASADKA4yIC5mZXJyZXQucmVtb3RlX2lucHV0LnYxLk'
    '1vZGlmaWVyUgRoZWxk');

@$core.Deprecated('Use enterScreenDescriptor instead')
const EnterScreen$json = {
  '1': 'EnterScreen',
  '2': [
    {
      '1': 'held',
      '3': 1,
      '4': 3,
      '5': 14,
      '6': '.ferret.remote_input.v1.Modifier',
      '10': 'held'
    },
  ],
};

/// Descriptor for `EnterScreen`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List enterScreenDescriptor = $convert.base64Decode(
    'CgtFbnRlclNjcmVlbhI0CgRoZWxkGAEgAygOMiAuZmVycmV0LnJlbW90ZV9pbnB1dC52MS5Nb2'
    'RpZmllclIEaGVsZA==');

@$core.Deprecated('Use leaveScreenDescriptor instead')
const LeaveScreen$json = {
  '1': 'LeaveScreen',
};

/// Descriptor for `LeaveScreen`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leaveScreenDescriptor =
    $convert.base64Decode('CgtMZWF2ZVNjcmVlbg==');

@$core.Deprecated('Use inputEventDescriptor instead')
const InputEvent$json = {
  '1': 'InputEvent',
  '2': [
    {
      '1': 'move',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.PointerMove',
      '9': 0,
      '10': 'move'
    },
    {
      '1': 'button',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.ButtonEvent',
      '9': 0,
      '10': 'button'
    },
    {
      '1': 'scroll',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.Scroll',
      '9': 0,
      '10': 'scroll'
    },
    {
      '1': 'key',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.KeyEvent',
      '9': 0,
      '10': 'key'
    },
    {
      '1': 'text',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.TextInput',
      '9': 0,
      '10': 'text'
    },
    {
      '1': 'modifiers',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.ModifierState',
      '9': 0,
      '10': 'modifiers'
    },
    {
      '1': 'enter',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.EnterScreen',
      '9': 0,
      '10': 'enter'
    },
    {
      '1': 'leave',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.LeaveScreen',
      '9': 0,
      '10': 'leave'
    },
  ],
  '8': [
    {'1': 'kind'},
  ],
};

/// Descriptor for `InputEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputEventDescriptor = $convert.base64Decode(
    'CgpJbnB1dEV2ZW50EjkKBG1vdmUYASABKAsyIy5mZXJyZXQucmVtb3RlX2lucHV0LnYxLlBvaW'
    '50ZXJNb3ZlSABSBG1vdmUSPQoGYnV0dG9uGAIgASgLMiMuZmVycmV0LnJlbW90ZV9pbnB1dC52'
    'MS5CdXR0b25FdmVudEgAUgZidXR0b24SOAoGc2Nyb2xsGAMgASgLMh4uZmVycmV0LnJlbW90ZV'
    '9pbnB1dC52MS5TY3JvbGxIAFIGc2Nyb2xsEjQKA2tleRgEIAEoCzIgLmZlcnJldC5yZW1vdGVf'
    'aW5wdXQudjEuS2V5RXZlbnRIAFIDa2V5EjcKBHRleHQYBSABKAsyIS5mZXJyZXQucmVtb3RlX2'
    'lucHV0LnYxLlRleHRJbnB1dEgAUgR0ZXh0EkUKCW1vZGlmaWVycxgGIAEoCzIlLmZlcnJldC5y'
    'ZW1vdGVfaW5wdXQudjEuTW9kaWZpZXJTdGF0ZUgAUgltb2RpZmllcnMSOwoFZW50ZXIYByABKA'
    'syIy5mZXJyZXQucmVtb3RlX2lucHV0LnYxLkVudGVyU2NyZWVuSABSBWVudGVyEjsKBWxlYXZl'
    'GAggASgLMiMuZmVycmV0LnJlbW90ZV9pbnB1dC52MS5MZWF2ZVNjcmVlbkgAUgVsZWF2ZUIGCg'
    'RraW5k');

@$core.Deprecated('Use inputBatchDescriptor instead')
const InputBatch$json = {
  '1': 'InputBatch',
  '2': [
    {
      '1': 'events',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.remote_input.v1.InputEvent',
      '10': 'events'
    },
  ],
};

/// Descriptor for `InputBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputBatchDescriptor = $convert.base64Decode(
    'CgpJbnB1dEJhdGNoEjoKBmV2ZW50cxgBIAMoCzIiLmZlcnJldC5yZW1vdGVfaW5wdXQudjEuSW'
    '5wdXRFdmVudFIGZXZlbnRz');

@$core.Deprecated('Use lockRequestDescriptor instead')
const LockRequest$json = {
  '1': 'LockRequest',
};

/// Descriptor for `LockRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockRequestDescriptor =
    $convert.base64Decode('CgtMb2NrUmVxdWVzdA==');

@$core.Deprecated('Use lockReplyDescriptor instead')
const LockReply$json = {
  '1': 'LockReply',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.remote_input.v1.LockResult',
      '10': 'result'
    },
  ],
};

/// Descriptor for `LockReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockReplyDescriptor = $convert.base64Decode(
    'CglMb2NrUmVwbHkSOgoGcmVzdWx0GAEgASgOMiIuZmVycmV0LnJlbW90ZV9pbnB1dC52MS5Mb2'
    'NrUmVzdWx0UgZyZXN1bHQ=');
