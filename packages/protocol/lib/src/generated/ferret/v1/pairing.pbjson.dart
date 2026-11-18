// This is a generated file - do not edit.
//
// Generated from ferret/v1/pairing.proto.

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

@$core.Deprecated('Use pairingResultDescriptor instead')
const PairingResult$json = {
  '1': 'PairingResult',
  '2': [
    {'1': 'PAIRING_RESULT_UNSPECIFIED', '2': 0},
    {'1': 'PAIRING_RESULT_ACCEPTED', '2': 1},
    {'1': 'PAIRING_RESULT_REJECTED', '2': 2},
    {'1': 'PAIRING_RESULT_EXPIRED', '2': 3},
    {'1': 'PAIRING_RESULT_BAD_PROOF', '2': 4},
    {'1': 'PAIRING_RESULT_TIMED_OUT', '2': 5},
  ],
};

/// Descriptor for `PairingResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pairingResultDescriptor = $convert.base64Decode(
    'Cg1QYWlyaW5nUmVzdWx0Eh4KGlBBSVJJTkdfUkVTVUxUX1VOU1BFQ0lGSUVEEAASGwoXUEFJUk'
    'lOR19SRVNVTFRfQUNDRVBURUQQARIbChdQQUlSSU5HX1JFU1VMVF9SRUpFQ1RFRBACEhoKFlBB'
    'SVJJTkdfUkVTVUxUX0VYUElSRUQQAxIcChhQQUlSSU5HX1JFU1VMVF9CQURfUFJPT0YQBBIcCh'
    'hQQUlSSU5HX1JFU1VMVF9USU1FRF9PVVQQBQ==');

@$core.Deprecated('Use pairingOfferDescriptor instead')
const PairingOffer$json = {
  '1': 'PairingOffer',
  '2': [
    {'1': 'protocol_version', '3': 1, '4': 1, '5': 13, '10': 'protocolVersion'},
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'platform',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.Platform',
      '10': 'platform'
    },
    {'1': 'hosts', '3': 5, '4': 3, '5': 9, '10': 'hosts'},
    {'1': 'port', '3': 6, '4': 1, '5': 13, '10': 'port'},
    {
      '1': 'static_public_key',
      '3': 7,
      '4': 1,
      '5': 12,
      '10': 'staticPublicKey'
    },
    {'1': 'secret', '3': 8, '4': 1, '5': 12, '10': 'secret'},
    {'1': 'expires_at_ms', '3': 9, '4': 1, '5': 4, '10': 'expiresAtMs'},
  ],
};

/// Descriptor for `PairingOffer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingOfferDescriptor = $convert.base64Decode(
    'CgxQYWlyaW5nT2ZmZXISKQoQcHJvdG9jb2xfdmVyc2lvbhgBIAEoDVIPcHJvdG9jb2xWZXJzaW'
    '9uEhsKCWRldmljZV9pZBgCIAEoCVIIZGV2aWNlSWQSEgoEbmFtZRgDIAEoCVIEbmFtZRIvCghw'
    'bGF0Zm9ybRgEIAEoDjITLmZlcnJldC52MS5QbGF0Zm9ybVIIcGxhdGZvcm0SFAoFaG9zdHMYBS'
    'ADKAlSBWhvc3RzEhIKBHBvcnQYBiABKA1SBHBvcnQSKgoRc3RhdGljX3B1YmxpY19rZXkYByAB'
    'KAxSD3N0YXRpY1B1YmxpY0tleRIWCgZzZWNyZXQYCCABKAxSBnNlY3JldBIiCg1leHBpcmVzX2'
    'F0X21zGAkgASgEUgtleHBpcmVzQXRNcw==');

@$core.Deprecated('Use pairingRequestDescriptor instead')
const PairingRequest$json = {
  '1': 'PairingRequest',
  '2': [
    {
      '1': 'device',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ferret.v1.DeviceInfo',
      '10': 'device'
    },
    {'1': 'proof', '3': 2, '4': 1, '5': 12, '10': 'proof'},
    {'1': 'commitment', '3': 3, '4': 1, '5': 12, '10': 'commitment'},
    {'1': 'also_devices', '3': 4, '4': 3, '5': 9, '10': 'alsoDevices'},
  ],
};

/// Descriptor for `PairingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingRequestDescriptor = $convert.base64Decode(
    'Cg5QYWlyaW5nUmVxdWVzdBItCgZkZXZpY2UYASABKAsyFS5mZXJyZXQudjEuRGV2aWNlSW5mb1'
    'IGZGV2aWNlEhQKBXByb29mGAIgASgMUgVwcm9vZhIeCgpjb21taXRtZW50GAMgASgMUgpjb21t'
    'aXRtZW50EiEKDGFsc29fZGV2aWNlcxgEIAMoCVILYWxzb0RldmljZXM=');

@$core.Deprecated('Use pairingChallengeDescriptor instead')
const PairingChallenge$json = {
  '1': 'PairingChallenge',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 12, '10': 'nonce'},
  ],
};

/// Descriptor for `PairingChallenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingChallengeDescriptor = $convert
    .base64Decode('ChBQYWlyaW5nQ2hhbGxlbmdlEhQKBW5vbmNlGAEgASgMUgVub25jZQ==');

@$core.Deprecated('Use pairingRevealDescriptor instead')
const PairingReveal$json = {
  '1': 'PairingReveal',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 12, '10': 'nonce'},
  ],
};

/// Descriptor for `PairingReveal`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingRevealDescriptor = $convert
    .base64Decode('Cg1QYWlyaW5nUmV2ZWFsEhQKBW5vbmNlGAEgASgMUgVub25jZQ==');

@$core.Deprecated('Use pairingConfirmDescriptor instead')
const PairingConfirm$json = {
  '1': 'PairingConfirm',
  '2': [
    {'1': 'accepted', '3': 1, '4': 1, '5': 8, '10': 'accepted'},
  ],
};

/// Descriptor for `PairingConfirm`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingConfirmDescriptor = $convert.base64Decode(
    'Cg5QYWlyaW5nQ29uZmlybRIaCghhY2NlcHRlZBgBIAEoCFIIYWNjZXB0ZWQ=');

@$core.Deprecated('Use pairingResponseDescriptor instead')
const PairingResponse$json = {
  '1': 'PairingResponse',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.PairingResult',
      '10': 'result'
    },
    {
      '1': 'device',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ferret.v1.DeviceInfo',
      '10': 'device'
    },
    {'1': 'proof', '3': 3, '4': 1, '5': 12, '10': 'proof'},
  ],
};

/// Descriptor for `PairingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pairingResponseDescriptor = $convert.base64Decode(
    'Cg9QYWlyaW5nUmVzcG9uc2USMAoGcmVzdWx0GAEgASgOMhguZmVycmV0LnYxLlBhaXJpbmdSZX'
    'N1bHRSBnJlc3VsdBItCgZkZXZpY2UYAiABKAsyFS5mZXJyZXQudjEuRGV2aWNlSW5mb1IGZGV2'
    'aWNlEhQKBXByb29mGAMgASgMUgVwcm9vZg==');

@$core.Deprecated('Use introduceDescriptor instead')
const Introduce$json = {
  '1': 'Introduce',
  '2': [
    {
      '1': 'devices',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.v1.IntroducedDevice',
      '10': 'devices'
    },
    {
      '1': 'forgotten',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.ferret.v1.ForgottenDevice',
      '10': 'forgotten'
    },
  ],
};

/// Descriptor for `Introduce`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List introduceDescriptor = $convert.base64Decode(
    'CglJbnRyb2R1Y2USNQoHZGV2aWNlcxgBIAMoCzIbLmZlcnJldC52MS5JbnRyb2R1Y2VkRGV2aW'
    'NlUgdkZXZpY2VzEjgKCWZvcmdvdHRlbhgCIAMoCzIaLmZlcnJldC52MS5Gb3Jnb3R0ZW5EZXZp'
    'Y2VSCWZvcmdvdHRlbg==');

@$core.Deprecated('Use introducedDeviceDescriptor instead')
const IntroducedDevice$json = {
  '1': 'IntroducedDevice',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'platform',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.Platform',
      '10': 'platform'
    },
    {
      '1': 'form_factor',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ferret.v1.FormFactor',
      '10': 'formFactor'
    },
    {
      '1': 'static_public_key',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'staticPublicKey'
    },
    {'1': 'host', '3': 6, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 7, '4': 1, '5': 13, '10': 'port'},
    {'1': 'paired_at_ms', '3': 8, '4': 1, '5': 4, '10': 'pairedAtMs'},
  ],
};

/// Descriptor for `IntroducedDevice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List introducedDeviceDescriptor = $convert.base64Decode(
    'ChBJbnRyb2R1Y2VkRGV2aWNlEg4KAmlkGAEgASgJUgJpZBISCgRuYW1lGAIgASgJUgRuYW1lEi'
    '8KCHBsYXRmb3JtGAMgASgOMhMuZmVycmV0LnYxLlBsYXRmb3JtUghwbGF0Zm9ybRI2Cgtmb3Jt'
    'X2ZhY3RvchgEIAEoDjIVLmZlcnJldC52MS5Gb3JtRmFjdG9yUgpmb3JtRmFjdG9yEioKEXN0YX'
    'RpY19wdWJsaWNfa2V5GAUgASgMUg9zdGF0aWNQdWJsaWNLZXkSEgoEaG9zdBgGIAEoCVIEaG9z'
    'dBISCgRwb3J0GAcgASgNUgRwb3J0EiAKDHBhaXJlZF9hdF9tcxgIIAEoBFIKcGFpcmVkQXRNcw'
    '==');

@$core.Deprecated('Use forgottenDeviceDescriptor instead')
const ForgottenDevice$json = {
  '1': 'ForgottenDevice',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'forgotten_at_ms', '3': 2, '4': 1, '5': 4, '10': 'forgottenAtMs'},
  ],
};

/// Descriptor for `ForgottenDevice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List forgottenDeviceDescriptor = $convert.base64Decode(
    'Cg9Gb3Jnb3R0ZW5EZXZpY2USDgoCaWQYASABKAlSAmlkEiYKD2ZvcmdvdHRlbl9hdF9tcxgCIA'
    'EoBFINZm9yZ290dGVuQXRNcw==');
