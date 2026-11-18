// This is a generated file - do not edit.
//
// Generated from ferret/calls/v1/calls.proto.

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

@$core.Deprecated('Use callDirectionDescriptor instead')
const CallDirection$json = {
  '1': 'CallDirection',
  '2': [
    {'1': 'CALL_DIRECTION_UNSPECIFIED', '2': 0},
    {'1': 'CALL_DIRECTION_INCOMING', '2': 1},
    {'1': 'CALL_DIRECTION_OUTGOING', '2': 2},
  ],
};

/// Descriptor for `CallDirection`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List callDirectionDescriptor = $convert.base64Decode(
    'Cg1DYWxsRGlyZWN0aW9uEh4KGkNBTExfRElSRUNUSU9OX1VOU1BFQ0lGSUVEEAASGwoXQ0FMTF'
    '9ESVJFQ1RJT05fSU5DT01JTkcQARIbChdDQUxMX0RJUkVDVElPTl9PVVRHT0lORxAC');

@$core.Deprecated('Use callStateDescriptor instead')
const CallState$json = {
  '1': 'CallState',
  '2': [
    {'1': 'CALL_STATE_UNSPECIFIED', '2': 0},
    {'1': 'CALL_STATE_RINGING', '2': 1},
    {'1': 'CALL_STATE_DIALING', '2': 2},
    {'1': 'CALL_STATE_ACTIVE', '2': 3},
    {'1': 'CALL_STATE_HELD', '2': 4},
    {'1': 'CALL_STATE_ENDED', '2': 5},
  ],
};

/// Descriptor for `CallState`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List callStateDescriptor = $convert.base64Decode(
    'CglDYWxsU3RhdGUSGgoWQ0FMTF9TVEFURV9VTlNQRUNJRklFRBAAEhYKEkNBTExfU1RBVEVfUk'
    'lOR0lORxABEhYKEkNBTExfU1RBVEVfRElBTElORxACEhUKEUNBTExfU1RBVEVfQUNUSVZFEAMS'
    'EwoPQ0FMTF9TVEFURV9IRUxEEAQSFAoQQ0FMTF9TVEFURV9FTkRFRBAF');

@$core.Deprecated('Use callOutcomeDescriptor instead')
const CallOutcome$json = {
  '1': 'CallOutcome',
  '2': [
    {'1': 'CALL_OUTCOME_UNSPECIFIED', '2': 0},
    {'1': 'CALL_OUTCOME_ANSWERED', '2': 1},
    {'1': 'CALL_OUTCOME_MISSED', '2': 2},
    {'1': 'CALL_OUTCOME_DECLINED', '2': 3},
  ],
};

/// Descriptor for `CallOutcome`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List callOutcomeDescriptor = $convert.base64Decode(
    'CgtDYWxsT3V0Y29tZRIcChhDQUxMX09VVENPTUVfVU5TUEVDSUZJRUQQABIZChVDQUxMX09VVE'
    'NPTUVfQU5TV0VSRUQQARIXChNDQUxMX09VVENPTUVfTUlTU0VEEAISGQoVQ0FMTF9PVVRDT01F'
    'X0RFQ0xJTkVEEAM=');

@$core.Deprecated('Use callActionDescriptor instead')
const CallAction$json = {
  '1': 'CallAction',
  '2': [
    {'1': 'CALL_ACTION_UNSPECIFIED', '2': 0},
    {'1': 'CALL_ACTION_ANSWER', '2': 1},
    {'1': 'CALL_ACTION_END', '2': 2},
    {'1': 'CALL_ACTION_SILENCE', '2': 3},
    {'1': 'CALL_ACTION_DIAL', '2': 4},
  ],
};

/// Descriptor for `CallAction`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List callActionDescriptor = $convert.base64Decode(
    'CgpDYWxsQWN0aW9uEhsKF0NBTExfQUNUSU9OX1VOU1BFQ0lGSUVEEAASFgoSQ0FMTF9BQ1RJT0'
    '5fQU5TV0VSEAESEwoPQ0FMTF9BQ1RJT05fRU5EEAISFwoTQ0FMTF9BQ1RJT05fU0lMRU5DRRAD'
    'EhQKEENBTExfQUNUSU9OX0RJQUwQBA==');

@$core.Deprecated('Use callCommandStatusDescriptor instead')
const CallCommandStatus$json = {
  '1': 'CallCommandStatus',
  '2': [
    {'1': 'CALL_COMMAND_STATUS_UNSPECIFIED', '2': 0},
    {'1': 'CALL_COMMAND_STATUS_OK', '2': 1},
    {'1': 'CALL_COMMAND_STATUS_NO_CALL', '2': 2},
    {'1': 'CALL_COMMAND_STATUS_DISABLED', '2': 3},
    {'1': 'CALL_COMMAND_STATUS_PERMISSION_MISSING', '2': 4},
    {'1': 'CALL_COMMAND_STATUS_UNSUPPORTED', '2': 5},
    {'1': 'CALL_COMMAND_STATUS_INVALID_NUMBER', '2': 6},
    {'1': 'CALL_COMMAND_STATUS_FAILED', '2': 7},
  ],
};

/// Descriptor for `CallCommandStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List callCommandStatusDescriptor = $convert.base64Decode(
    'ChFDYWxsQ29tbWFuZFN0YXR1cxIjCh9DQUxMX0NPTU1BTkRfU1RBVFVTX1VOU1BFQ0lGSUVEEA'
    'ASGgoWQ0FMTF9DT01NQU5EX1NUQVRVU19PSxABEh8KG0NBTExfQ09NTUFORF9TVEFUVVNfTk9f'
    'Q0FMTBACEiAKHENBTExfQ09NTUFORF9TVEFUVVNfRElTQUJMRUQQAxIqCiZDQUxMX0NPTU1BTk'
    'RfU1RBVFVTX1BFUk1JU1NJT05fTUlTU0lORxAEEiMKH0NBTExfQ09NTUFORF9TVEFUVVNfVU5T'
    'VVBQT1JURUQQBRImCiJDQUxMX0NPTU1BTkRfU1RBVFVTX0lOVkFMSURfTlVNQkVSEAYSHgoaQ0'
    'FMTF9DT01NQU5EX1NUQVRVU19GQUlMRUQQBw==');

@$core.Deprecated('Use callLogTypeDescriptor instead')
const CallLogType$json = {
  '1': 'CallLogType',
  '2': [
    {'1': 'CALL_LOG_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'CALL_LOG_TYPE_INCOMING', '2': 1},
    {'1': 'CALL_LOG_TYPE_OUTGOING', '2': 2},
    {'1': 'CALL_LOG_TYPE_MISSED', '2': 3},
    {'1': 'CALL_LOG_TYPE_REJECTED', '2': 4},
  ],
};

/// Descriptor for `CallLogType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List callLogTypeDescriptor = $convert.base64Decode(
    'CgtDYWxsTG9nVHlwZRIdChlDQUxMX0xPR19UWVBFX1VOU1BFQ0lGSUVEEAASGgoWQ0FMTF9MT0'
    'dfVFlQRV9JTkNPTUlORxABEhoKFkNBTExfTE9HX1RZUEVfT1VUR09JTkcQAhIYChRDQUxMX0xP'
    'R19UWVBFX01JU1NFRBADEhoKFkNBTExfTE9HX1RZUEVfUkVKRUNURUQQBA==');

@$core.Deprecated('Use callDescriptor instead')
const Call$json = {
  '1': 'Call',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'number', '3': 2, '4': 1, '5': 9, '10': 'number'},
    {'1': 'contact_name', '3': 3, '4': 1, '5': 9, '10': 'contactName'},
    {'1': 'photo_jpeg', '3': 4, '4': 1, '5': 12, '10': 'photoJpeg'},
    {
      '1': 'direction',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.ferret.calls.v1.CallDirection',
      '10': 'direction'
    },
    {
      '1': 'state',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.ferret.calls.v1.CallState',
      '10': 'state'
    },
    {'1': 'started_at_ms', '3': 7, '4': 1, '5': 3, '10': 'startedAtMs'},
    {'1': 'connected_at_ms', '3': 8, '4': 1, '5': 3, '10': 'connectedAtMs'},
    {
      '1': 'outcome',
      '3': 9,
      '4': 1,
      '5': 14,
      '6': '.ferret.calls.v1.CallOutcome',
      '10': 'outcome'
    },
  ],
};

/// Descriptor for `Call`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callDescriptor = $convert.base64Decode(
    'CgRDYWxsEg4KAmlkGAEgASgJUgJpZBIWCgZudW1iZXIYAiABKAlSBm51bWJlchIhCgxjb250YW'
    'N0X25hbWUYAyABKAlSC2NvbnRhY3ROYW1lEh0KCnBob3RvX2pwZWcYBCABKAxSCXBob3RvSnBl'
    'ZxI8CglkaXJlY3Rpb24YBSABKA4yHi5mZXJyZXQuY2FsbHMudjEuQ2FsbERpcmVjdGlvblIJZG'
    'lyZWN0aW9uEjAKBXN0YXRlGAYgASgOMhouZmVycmV0LmNhbGxzLnYxLkNhbGxTdGF0ZVIFc3Rh'
    'dGUSIgoNc3RhcnRlZF9hdF9tcxgHIAEoA1ILc3RhcnRlZEF0TXMSJgoPY29ubmVjdGVkX2F0X2'
    '1zGAggASgDUg1jb25uZWN0ZWRBdE1zEjYKB291dGNvbWUYCSABKA4yHC5mZXJyZXQuY2FsbHMu'
    'djEuQ2FsbE91dGNvbWVSB291dGNvbWU=');

@$core.Deprecated('Use callUpdateDescriptor instead')
const CallUpdate$json = {
  '1': 'CallUpdate',
  '2': [
    {
      '1': 'call',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ferret.calls.v1.Call',
      '10': 'call'
    },
    {'1': 'sent_at_ms', '3': 2, '4': 1, '5': 3, '10': 'sentAtMs'},
  ],
};

/// Descriptor for `CallUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callUpdateDescriptor = $convert.base64Decode(
    'CgpDYWxsVXBkYXRlEikKBGNhbGwYASABKAsyFS5mZXJyZXQuY2FsbHMudjEuQ2FsbFIEY2FsbB'
    'IcCgpzZW50X2F0X21zGAIgASgDUghzZW50QXRNcw==');

@$core.Deprecated('Use callCommandDescriptor instead')
const CallCommand$json = {
  '1': 'CallCommand',
  '2': [
    {
      '1': 'action',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.calls.v1.CallAction',
      '10': 'action'
    },
    {'1': 'call_id', '3': 2, '4': 1, '5': 9, '10': 'callId'},
    {'1': 'number', '3': 3, '4': 1, '5': 9, '10': 'number'},
  ],
};

/// Descriptor for `CallCommand`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callCommandDescriptor = $convert.base64Decode(
    'CgtDYWxsQ29tbWFuZBIzCgZhY3Rpb24YASABKA4yGy5mZXJyZXQuY2FsbHMudjEuQ2FsbEFjdG'
    'lvblIGYWN0aW9uEhcKB2NhbGxfaWQYAiABKAlSBmNhbGxJZBIWCgZudW1iZXIYAyABKAlSBm51'
    'bWJlcg==');

@$core.Deprecated('Use callCommandResultDescriptor instead')
const CallCommandResult$json = {
  '1': 'CallCommandResult',
  '2': [
    {
      '1': 'status',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.calls.v1.CallCommandStatus',
      '10': 'status'
    },
  ],
};

/// Descriptor for `CallCommandResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callCommandResultDescriptor = $convert.base64Decode(
    'ChFDYWxsQ29tbWFuZFJlc3VsdBI6CgZzdGF0dXMYASABKA4yIi5mZXJyZXQuY2FsbHMudjEuQ2'
    'FsbENvbW1hbmRTdGF0dXNSBnN0YXR1cw==');

@$core.Deprecated('Use getCallsStatusDescriptor instead')
const GetCallsStatus$json = {
  '1': 'GetCallsStatus',
};

/// Descriptor for `GetCallsStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCallsStatusDescriptor =
    $convert.base64Decode('Cg5HZXRDYWxsc1N0YXR1cw==');

@$core.Deprecated('Use callsStatusDescriptor instead')
const CallsStatus$json = {
  '1': 'CallsStatus',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'can_see_calls', '3': 2, '4': 1, '5': 8, '10': 'canSeeCalls'},
    {'1': 'can_see_numbers', '3': 3, '4': 1, '5': 8, '10': 'canSeeNumbers'},
    {'1': 'can_answer', '3': 4, '4': 1, '5': 8, '10': 'canAnswer'},
    {'1': 'can_dial', '3': 5, '4': 1, '5': 8, '10': 'canDial'},
    {'1': 'can_read_log', '3': 6, '4': 1, '5': 8, '10': 'canReadLog'},
    {'1': 'can_read_contacts', '3': 7, '4': 1, '5': 8, '10': 'canReadContacts'},
  ],
};

/// Descriptor for `CallsStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callsStatusDescriptor = $convert.base64Decode(
    'CgtDYWxsc1N0YXR1cxIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEiIKDWNhbl9zZWVfY2FsbH'
    'MYAiABKAhSC2NhblNlZUNhbGxzEiYKD2Nhbl9zZWVfbnVtYmVycxgDIAEoCFINY2FuU2VlTnVt'
    'YmVycxIdCgpjYW5fYW5zd2VyGAQgASgIUgljYW5BbnN3ZXISGQoIY2FuX2RpYWwYBSABKAhSB2'
    'NhbkRpYWwSIAoMY2FuX3JlYWRfbG9nGAYgASgIUgpjYW5SZWFkTG9nEioKEWNhbl9yZWFkX2Nv'
    'bnRhY3RzGAcgASgIUg9jYW5SZWFkQ29udGFjdHM=');

@$core.Deprecated('Use callLogEntryDescriptor instead')
const CallLogEntry$json = {
  '1': 'CallLogEntry',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'number', '3': 2, '4': 1, '5': 9, '10': 'number'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'type',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ferret.calls.v1.CallLogType',
      '10': 'type'
    },
    {'1': 'date_ms', '3': 5, '4': 1, '5': 3, '10': 'dateMs'},
    {'1': 'duration_s', '3': 6, '4': 1, '5': 3, '10': 'durationS'},
  ],
};

/// Descriptor for `CallLogEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callLogEntryDescriptor = $convert.base64Decode(
    'CgxDYWxsTG9nRW50cnkSDgoCaWQYASABKAlSAmlkEhYKBm51bWJlchgCIAEoCVIGbnVtYmVyEh'
    'IKBG5hbWUYAyABKAlSBG5hbWUSMAoEdHlwZRgEIAEoDjIcLmZlcnJldC5jYWxscy52MS5DYWxs'
    'TG9nVHlwZVIEdHlwZRIXCgdkYXRlX21zGAUgASgDUgZkYXRlTXMSHQoKZHVyYXRpb25fcxgGIA'
    'EoA1IJZHVyYXRpb25T');

@$core.Deprecated('Use getCallLogDescriptor instead')
const GetCallLog$json = {
  '1': 'GetCallLog',
  '2': [
    {'1': 'limit', '3': 1, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `GetCallLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getCallLogDescriptor =
    $convert.base64Decode('CgpHZXRDYWxsTG9nEhQKBWxpbWl0GAEgASgNUgVsaW1pdA==');

@$core.Deprecated('Use callLogDescriptor instead')
const CallLog$json = {
  '1': 'CallLog',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.calls.v1.CallLogEntry',
      '10': 'entries'
    },
    {
      '1': 'permission_missing',
      '3': 2,
      '4': 1,
      '5': 8,
      '10': 'permissionMissing'
    },
    {'1': 'disabled', '3': 3, '4': 1, '5': 8, '10': 'disabled'},
  ],
};

/// Descriptor for `CallLog`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List callLogDescriptor = $convert.base64Decode(
    'CgdDYWxsTG9nEjcKB2VudHJpZXMYASADKAsyHS5mZXJyZXQuY2FsbHMudjEuQ2FsbExvZ0VudH'
    'J5UgdlbnRyaWVzEi0KEnBlcm1pc3Npb25fbWlzc2luZxgCIAEoCFIRcGVybWlzc2lvbk1pc3Np'
    'bmcSGgoIZGlzYWJsZWQYAyABKAhSCGRpc2FibGVk');
