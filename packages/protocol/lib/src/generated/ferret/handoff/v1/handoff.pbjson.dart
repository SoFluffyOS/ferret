// This is a generated file - do not edit.
//
// Generated from ferret/handoff/v1/handoff.proto.

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

@$core.Deprecated('Use activityKindDescriptor instead')
const ActivityKind$json = {
  '1': 'ActivityKind',
  '2': [
    {'1': 'ACTIVITY_KIND_UNSPECIFIED', '2': 0},
    {'1': 'ACTIVITY_KIND_WEB', '2': 1},
    {'1': 'ACTIVITY_KIND_APP', '2': 2},
    {'1': 'ACTIVITY_KIND_GEO', '2': 3},
    {'1': 'ACTIVITY_KIND_TEXT', '2': 4},
  ],
};

/// Descriptor for `ActivityKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List activityKindDescriptor = $convert.base64Decode(
    'CgxBY3Rpdml0eUtpbmQSHQoZQUNUSVZJVFlfS0lORF9VTlNQRUNJRklFRBAAEhUKEUFDVElWSV'
    'RZX0tJTkRfV0VCEAESFQoRQUNUSVZJVFlfS0lORF9BUFAQAhIVChFBQ1RJVklUWV9LSU5EX0dF'
    'TxADEhYKEkFDVElWSVRZX0tJTkRfVEVYVBAE');

@$core.Deprecated('Use continueOutcomeDescriptor instead')
const ContinueOutcome$json = {
  '1': 'ContinueOutcome',
  '2': [
    {'1': 'CONTINUE_OUTCOME_UNSPECIFIED', '2': 0},
    {'1': 'CONTINUE_OUTCOME_OPENED', '2': 1},
    {'1': 'CONTINUE_OUTCOME_SUGGESTED', '2': 2},
    {'1': 'CONTINUE_OUTCOME_FAILED', '2': 3},
  ],
};

/// Descriptor for `ContinueOutcome`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List continueOutcomeDescriptor = $convert.base64Decode(
    'Cg9Db250aW51ZU91dGNvbWUSIAocQ09OVElOVUVfT1VUQ09NRV9VTlNQRUNJRklFRBAAEhsKF0'
    'NPTlRJTlVFX09VVENPTUVfT1BFTkVEEAESHgoaQ09OVElOVUVfT1VUQ09NRV9TVUdHRVNURUQQ'
    'AhIbChdDT05USU5VRV9PVVRDT01FX0ZBSUxFRBAD');

@$core.Deprecated('Use appIdentifiersDescriptor instead')
const AppIdentifiers$json = {
  '1': 'AppIdentifiers',
  '2': [
    {'1': 'android_package', '3': 1, '4': 1, '5': 9, '10': 'androidPackage'},
    {'1': 'apple_bundle_id', '3': 2, '4': 1, '5': 9, '10': 'appleBundleId'},
    {'1': 'linux_desktop_id', '3': 3, '4': 1, '5': 9, '10': 'linuxDesktopId'},
    {'1': 'windows_app_id', '3': 4, '4': 1, '5': 9, '10': 'windowsAppId'},
  ],
};

/// Descriptor for `AppIdentifiers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appIdentifiersDescriptor = $convert.base64Decode(
    'Cg5BcHBJZGVudGlmaWVycxInCg9hbmRyb2lkX3BhY2thZ2UYASABKAlSDmFuZHJvaWRQYWNrYW'
    'dlEiYKD2FwcGxlX2J1bmRsZV9pZBgCIAEoCVINYXBwbGVCdW5kbGVJZBIoChBsaW51eF9kZXNr'
    'dG9wX2lkGAMgASgJUg5saW51eERlc2t0b3BJZBIkCg53aW5kb3dzX2FwcF9pZBgEIAEoCVIMd2'
    'luZG93c0FwcElk');

@$core.Deprecated('Use activityDescriptor instead')
const Activity$json = {
  '1': 'Activity',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.handoff.v1.ActivityKind',
      '10': 'kind'
    },
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'uri', '3': 4, '4': 1, '5': 9, '10': 'uri'},
    {'1': 'deep_link', '3': 5, '4': 1, '5': 9, '10': 'deepLink'},
    {
      '1': 'apps',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.ferret.handoff.v1.AppIdentifiers',
      '10': 'apps'
    },
    {'1': 'fallback_web_uri', '3': 7, '4': 1, '5': 9, '10': 'fallbackWebUri'},
    {'1': 'text', '3': 8, '4': 1, '5': 9, '10': 'text'},
    {'1': 'state', '3': 9, '4': 1, '5': 12, '10': 'state'},
    {'1': 'state_type', '3': 10, '4': 1, '5': 9, '10': 'stateType'},
    {'1': 'created_at_ms', '3': 11, '4': 1, '5': 4, '10': 'createdAtMs'},
    {'1': 'expires_at_ms', '3': 12, '4': 1, '5': 4, '10': 'expiresAtMs'},
    {'1': 'source_device_id', '3': 13, '4': 1, '5': 9, '10': 'sourceDeviceId'},
    {'1': 'source_app_name', '3': 14, '4': 1, '5': 9, '10': 'sourceAppName'},
  ],
};

/// Descriptor for `Activity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activityDescriptor = $convert.base64Decode(
    'CghBY3Rpdml0eRIOCgJpZBgBIAEoCVICaWQSMwoEa2luZBgCIAEoDjIfLmZlcnJldC5oYW5kb2'
    'ZmLnYxLkFjdGl2aXR5S2luZFIEa2luZBIUCgV0aXRsZRgDIAEoCVIFdGl0bGUSEAoDdXJpGAQg'
    'ASgJUgN1cmkSGwoJZGVlcF9saW5rGAUgASgJUghkZWVwTGluaxI1CgRhcHBzGAYgASgLMiEuZm'
    'VycmV0LmhhbmRvZmYudjEuQXBwSWRlbnRpZmllcnNSBGFwcHMSKAoQZmFsbGJhY2tfd2ViX3Vy'
    'aRgHIAEoCVIOZmFsbGJhY2tXZWJVcmkSEgoEdGV4dBgIIAEoCVIEdGV4dBIUCgVzdGF0ZRgJIA'
    'EoDFIFc3RhdGUSHQoKc3RhdGVfdHlwZRgKIAEoCVIJc3RhdGVUeXBlEiIKDWNyZWF0ZWRfYXRf'
    'bXMYCyABKARSC2NyZWF0ZWRBdE1zEiIKDWV4cGlyZXNfYXRfbXMYDCABKARSC2V4cGlyZXNBdE'
    '1zEigKEHNvdXJjZV9kZXZpY2VfaWQYDSABKAlSDnNvdXJjZURldmljZUlkEiYKD3NvdXJjZV9h'
    'cHBfbmFtZRgOIAEoCVINc291cmNlQXBwTmFtZQ==');

@$core.Deprecated('Use publishActivityDescriptor instead')
const PublishActivity$json = {
  '1': 'PublishActivity',
  '2': [
    {
      '1': 'activity',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ferret.handoff.v1.Activity',
      '10': 'activity'
    },
  ],
};

/// Descriptor for `PublishActivity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publishActivityDescriptor = $convert.base64Decode(
    'Cg9QdWJsaXNoQWN0aXZpdHkSNwoIYWN0aXZpdHkYASABKAsyGy5mZXJyZXQuaGFuZG9mZi52MS'
    '5BY3Rpdml0eVIIYWN0aXZpdHk=');

@$core.Deprecated('Use continueActivityDescriptor instead')
const ContinueActivity$json = {
  '1': 'ContinueActivity',
  '2': [
    {
      '1': 'activity',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ferret.handoff.v1.Activity',
      '10': 'activity'
    },
  ],
};

/// Descriptor for `ContinueActivity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List continueActivityDescriptor = $convert.base64Decode(
    'ChBDb250aW51ZUFjdGl2aXR5EjcKCGFjdGl2aXR5GAEgASgLMhsuZmVycmV0LmhhbmRvZmYudj'
    'EuQWN0aXZpdHlSCGFjdGl2aXR5');

@$core.Deprecated('Use continueResultDescriptor instead')
const ContinueResult$json = {
  '1': 'ContinueResult',
  '2': [
    {
      '1': 'outcome',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.handoff.v1.ContinueOutcome',
      '10': 'outcome'
    },
  ],
};

/// Descriptor for `ContinueResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List continueResultDescriptor = $convert.base64Decode(
    'Cg5Db250aW51ZVJlc3VsdBI8CgdvdXRjb21lGAEgASgOMiIuZmVycmV0LmhhbmRvZmYudjEuQ2'
    '9udGludWVPdXRjb21lUgdvdXRjb21l');

@$core.Deprecated('Use clearActivityDescriptor instead')
const ClearActivity$json = {
  '1': 'ClearActivity',
  '2': [
    {'1': 'activity_id', '3': 1, '4': 1, '5': 9, '10': 'activityId'},
  ],
};

/// Descriptor for `ClearActivity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clearActivityDescriptor = $convert.base64Decode(
    'Cg1DbGVhckFjdGl2aXR5Eh8KC2FjdGl2aXR5X2lkGAEgASgJUgphY3Rpdml0eUlk');
