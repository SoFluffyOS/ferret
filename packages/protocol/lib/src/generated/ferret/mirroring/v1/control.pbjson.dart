// This is a generated file - do not edit.
//
// Generated from ferret/mirroring/v1/control.proto.

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

@$core.Deprecated('Use controlStatusDescriptor instead')
const ControlStatus$json = {
  '1': 'ControlStatus',
  '2': [
    {'1': 'CONTROL_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'CONTROL_STATUS_CAN_ASK', '2': 1},
    {'1': 'CONTROL_STATUS_ASKING', '2': 2},
    {'1': 'CONTROL_STATUS_ALLOWED', '2': 3},
    {'1': 'CONTROL_STATUS_DENIED', '2': 4},
    {'1': 'CONTROL_STATUS_TIMED_OUT', '2': 5},
    {'1': 'CONTROL_STATUS_NEEDS_SETUP', '2': 6},
    {'1': 'CONTROL_STATUS_UNSUPPORTED', '2': 7},
    {'1': 'CONTROL_STATUS_STOPPED', '2': 8},
  ],
};

/// Descriptor for `ControlStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List controlStatusDescriptor = $convert.base64Decode(
    'Cg1Db250cm9sU3RhdHVzEh4KGkNPTlRST0xfU1RBVFVTX1VOU1BFQ0lGSUVEEAASGgoWQ09OVF'
    'JPTF9TVEFUVVNfQ0FOX0FTSxABEhkKFUNPTlRST0xfU1RBVFVTX0FTS0lORxACEhoKFkNPTlRS'
    'T0xfU1RBVFVTX0FMTE9XRUQQAxIZChVDT05UUk9MX1NUQVRVU19ERU5JRUQQBBIcChhDT05UUk'
    '9MX1NUQVRVU19USU1FRF9PVVQQBRIeChpDT05UUk9MX1NUQVRVU19ORUVEU19TRVRVUBAGEh4K'
    'GkNPTlRST0xfU1RBVFVTX1VOU1VQUE9SVEVEEAcSGgoWQ09OVFJPTF9TVEFUVVNfU1RPUFBFRB'
    'AI');

@$core.Deprecated('Use controlKindDescriptor instead')
const ControlKind$json = {
  '1': 'ControlKind',
  '2': [
    {'1': 'CONTROL_KIND_UNSPECIFIED', '2': 0},
    {'1': 'CONTROL_KIND_POINTER', '2': 1},
    {'1': 'CONTROL_KIND_KEYS', '2': 2},
    {'1': 'CONTROL_KIND_TEXT', '2': 3},
    {'1': 'CONTROL_KIND_BUTTONS', '2': 4},
    {'1': 'CONTROL_KIND_MOUSE', '2': 5},
  ],
};

/// Descriptor for `ControlKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List controlKindDescriptor = $convert.base64Decode(
    'CgtDb250cm9sS2luZBIcChhDT05UUk9MX0tJTkRfVU5TUEVDSUZJRUQQABIYChRDT05UUk9MX0'
    'tJTkRfUE9JTlRFUhABEhUKEUNPTlRST0xfS0lORF9LRVlTEAISFQoRQ09OVFJPTF9LSU5EX1RF'
    'WFQQAxIYChRDT05UUk9MX0tJTkRfQlVUVE9OUxAEEhYKEkNPTlRST0xfS0lORF9NT1VTRRAF');

@$core.Deprecated('Use touchPhaseDescriptor instead')
const TouchPhase$json = {
  '1': 'TouchPhase',
  '2': [
    {'1': 'TOUCH_PHASE_UNSPECIFIED', '2': 0},
    {'1': 'TOUCH_PHASE_DOWN', '2': 1},
    {'1': 'TOUCH_PHASE_MOVE', '2': 2},
    {'1': 'TOUCH_PHASE_UP', '2': 3},
    {'1': 'TOUCH_PHASE_CANCEL', '2': 4},
    {'1': 'TOUCH_PHASE_SCROLL', '2': 5},
    {'1': 'TOUCH_PHASE_HOVER', '2': 6},
  ],
};

/// Descriptor for `TouchPhase`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List touchPhaseDescriptor = $convert.base64Decode(
    'CgpUb3VjaFBoYXNlEhsKF1RPVUNIX1BIQVNFX1VOU1BFQ0lGSUVEEAASFAoQVE9VQ0hfUEhBU0'
    'VfRE9XThABEhQKEFRPVUNIX1BIQVNFX01PVkUQAhISCg5UT1VDSF9QSEFTRV9VUBADEhYKElRP'
    'VUNIX1BIQVNFX0NBTkNFTBAEEhYKElRPVUNIX1BIQVNFX1NDUk9MTBAFEhUKEVRPVUNIX1BIQV'
    'NFX0hPVkVSEAY=');

@$core.Deprecated('Use controlButtonDescriptor instead')
const ControlButton$json = {
  '1': 'ControlButton',
  '2': [
    {'1': 'CONTROL_BUTTON_UNSPECIFIED', '2': 0},
    {'1': 'CONTROL_BUTTON_BACK', '2': 1},
    {'1': 'CONTROL_BUTTON_HOME', '2': 2},
    {'1': 'CONTROL_BUTTON_RECENTS', '2': 3},
    {'1': 'CONTROL_BUTTON_NOTIFICATIONS', '2': 4},
    {'1': 'CONTROL_BUTTON_POWER', '2': 5},
    {'1': 'CONTROL_BUTTON_VOLUME_UP', '2': 6},
    {'1': 'CONTROL_BUTTON_VOLUME_DOWN', '2': 7},
  ],
};

/// Descriptor for `ControlButton`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List controlButtonDescriptor = $convert.base64Decode(
    'Cg1Db250cm9sQnV0dG9uEh4KGkNPTlRST0xfQlVUVE9OX1VOU1BFQ0lGSUVEEAASFwoTQ09OVF'
    'JPTF9CVVRUT05fQkFDSxABEhcKE0NPTlRST0xfQlVUVE9OX0hPTUUQAhIaChZDT05UUk9MX0JV'
    'VFRPTl9SRUNFTlRTEAMSIAocQ09OVFJPTF9CVVRUT05fTk9USUZJQ0FUSU9OUxAEEhgKFENPTl'
    'RST0xfQlVUVE9OX1BPV0VSEAUSHAoYQ09OVFJPTF9CVVRUT05fVk9MVU1FX1VQEAYSHgoaQ09O'
    'VFJPTF9CVVRUT05fVk9MVU1FX0RPV04QBw==');

@$core.Deprecated('Use controlStateDescriptor instead')
const ControlState$json = {
  '1': 'ControlState',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.ControlStatus',
      '10': 'status'
    },
    {
      '1': 'kinds',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.ferret.mirroring.v1.ControlKind',
      '10': 'kinds'
    },
    {'1': 'timeout_seconds', '3': 3, '4': 1, '5': 13, '10': 'timeoutSeconds'},
    {
      '1': 'buttons',
      '3': 4,
      '4': 3,
      '5': 14,
      '6': '.ferret.mirroring.v1.ControlButton',
      '10': 'buttons'
    },
  ],
};

/// Descriptor for `ControlState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlStateDescriptor = $convert.base64Decode(
    'CgxDb250cm9sU3RhdGUSOgoGc3RhdHVzGAEgASgOMiIuZmVycmV0Lm1pcnJvcmluZy52MS5Db2'
    '50cm9sU3RhdHVzUgZzdGF0dXMSNgoFa2luZHMYAiADKA4yIC5mZXJyZXQubWlycm9yaW5nLnYx'
    'LkNvbnRyb2xLaW5kUgVraW5kcxInCg90aW1lb3V0X3NlY29uZHMYAyABKA1SDnRpbWVvdXRTZW'
    'NvbmRzEjwKB2J1dHRvbnMYBCADKA4yIi5mZXJyZXQubWlycm9yaW5nLnYxLkNvbnRyb2xCdXR0'
    'b25SB2J1dHRvbnM=');

@$core.Deprecated('Use controlAskDescriptor instead')
const ControlAsk$json = {
  '1': 'ControlAsk',
};

/// Descriptor for `ControlAsk`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlAskDescriptor =
    $convert.base64Decode('CgpDb250cm9sQXNr');

@$core.Deprecated('Use controlReleaseDescriptor instead')
const ControlRelease$json = {
  '1': 'ControlRelease',
};

/// Descriptor for `ControlRelease`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlReleaseDescriptor =
    $convert.base64Decode('Cg5Db250cm9sUmVsZWFzZQ==');

@$core.Deprecated('Use pointerInputDescriptor instead')
const PointerInput$json = {
  '1': 'PointerInput',
  '2': [
    {
      '1': 'phase',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.TouchPhase',
      '10': 'phase'
    },
    {'1': 'x', '3': 2, '4': 1, '5': 2, '10': 'x'},
    {'1': 'y', '3': 3, '4': 1, '5': 2, '10': 'y'},
    {'1': 'scroll_x', '3': 4, '4': 1, '5': 2, '10': 'scrollX'},
    {'1': 'scroll_y', '3': 5, '4': 1, '5': 2, '10': 'scrollY'},
    {
      '1': 'button',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.ferret.remote_input.v1.MouseButton',
      '10': 'button'
    },
  ],
};

/// Descriptor for `PointerInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pointerInputDescriptor = $convert.base64Decode(
    'CgxQb2ludGVySW5wdXQSNQoFcGhhc2UYASABKA4yHy5mZXJyZXQubWlycm9yaW5nLnYxLlRvdW'
    'NoUGhhc2VSBXBoYXNlEgwKAXgYAiABKAJSAXgSDAoBeRgDIAEoAlIBeRIZCghzY3JvbGxfeBgE'
    'IAEoAlIHc2Nyb2xsWBIZCghzY3JvbGxfeRgFIAEoAlIHc2Nyb2xsWRI7CgZidXR0b24YBiABKA'
    '4yIy5mZXJyZXQucmVtb3RlX2lucHV0LnYxLk1vdXNlQnV0dG9uUgZidXR0b24=');

@$core.Deprecated('Use buttonPressDescriptor instead')
const ButtonPress$json = {
  '1': 'ButtonPress',
  '2': [
    {
      '1': 'button',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.ControlButton',
      '10': 'button'
    },
  ],
};

/// Descriptor for `ButtonPress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buttonPressDescriptor = $convert.base64Decode(
    'CgtCdXR0b25QcmVzcxI6CgZidXR0b24YASABKA4yIi5mZXJyZXQubWlycm9yaW5nLnYxLkNvbn'
    'Ryb2xCdXR0b25SBmJ1dHRvbg==');

@$core.Deprecated('Use controlEventDescriptor instead')
const ControlEvent$json = {
  '1': 'ControlEvent',
  '2': [
    {
      '1': 'pointer',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ferret.mirroring.v1.PointerInput',
      '9': 0,
      '10': 'pointer'
    },
    {
      '1': 'key',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.KeyEvent',
      '9': 0,
      '10': 'key'
    },
    {
      '1': 'text',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.ferret.remote_input.v1.TextInput',
      '9': 0,
      '10': 'text'
    },
    {
      '1': 'button',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.ferret.mirroring.v1.ButtonPress',
      '9': 0,
      '10': 'button'
    },
  ],
  '8': [
    {'1': 'kind'},
  ],
};

/// Descriptor for `ControlEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlEventDescriptor = $convert.base64Decode(
    'CgxDb250cm9sRXZlbnQSPQoHcG9pbnRlchgBIAEoCzIhLmZlcnJldC5taXJyb3JpbmcudjEuUG'
    '9pbnRlcklucHV0SABSB3BvaW50ZXISNAoDa2V5GAIgASgLMiAuZmVycmV0LnJlbW90ZV9pbnB1'
    'dC52MS5LZXlFdmVudEgAUgNrZXkSNwoEdGV4dBgDIAEoCzIhLmZlcnJldC5yZW1vdGVfaW5wdX'
    'QudjEuVGV4dElucHV0SABSBHRleHQSOgoGYnV0dG9uGAQgASgLMiAuZmVycmV0Lm1pcnJvcmlu'
    'Zy52MS5CdXR0b25QcmVzc0gAUgZidXR0b25CBgoEa2luZA==');

@$core.Deprecated('Use controlInputDescriptor instead')
const ControlInput$json = {
  '1': 'ControlInput',
  '2': [
    {
      '1': 'events',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.mirroring.v1.ControlEvent',
      '10': 'events'
    },
  ],
};

/// Descriptor for `ControlInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List controlInputDescriptor = $convert.base64Decode(
    'CgxDb250cm9sSW5wdXQSOQoGZXZlbnRzGAEgAygLMiEuZmVycmV0Lm1pcnJvcmluZy52MS5Db2'
    '50cm9sRXZlbnRSBmV2ZW50cw==');
