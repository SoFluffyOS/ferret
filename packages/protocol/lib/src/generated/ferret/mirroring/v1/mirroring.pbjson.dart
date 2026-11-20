// This is a generated file - do not edit.
//
// Generated from ferret/mirroring/v1/mirroring.proto.

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

@$core.Deprecated('Use codecDescriptor instead')
const Codec$json = {
  '1': 'Codec',
  '2': [
    {'1': 'CODEC_UNSPECIFIED', '2': 0},
    {'1': 'CODEC_H264', '2': 1},
    {'1': 'CODEC_JPEG', '2': 2},
  ],
};

/// Descriptor for `Codec`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List codecDescriptor = $convert.base64Decode(
    'CgVDb2RlYxIVChFDT0RFQ19VTlNQRUNJRklFRBAAEg4KCkNPREVDX0gyNjQQARIOCgpDT0RFQ1'
    '9KUEVHEAI=');

@$core.Deprecated('Use audioCodecDescriptor instead')
const AudioCodec$json = {
  '1': 'AudioCodec',
  '2': [
    {'1': 'AUDIO_CODEC_UNSPECIFIED', '2': 0},
    {'1': 'AUDIO_CODEC_OPUS', '2': 1},
    {'1': 'AUDIO_CODEC_PCM_S16LE', '2': 2},
  ],
};

/// Descriptor for `AudioCodec`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List audioCodecDescriptor = $convert.base64Decode(
    'CgpBdWRpb0NvZGVjEhsKF0FVRElPX0NPREVDX1VOU1BFQ0lGSUVEEAASFAoQQVVESU9fQ09ERU'
    'NfT1BVUxABEhkKFUFVRElPX0NPREVDX1BDTV9TMTZMRRAC');

@$core.Deprecated('Use sourceDescriptor instead')
const Source$json = {
  '1': 'Source',
  '2': [
    {'1': 'SOURCE_UNSPECIFIED', '2': 0},
    {'1': 'SOURCE_SCREEN', '2': 1},
    {'1': 'SOURCE_CAMERA', '2': 2},
  ],
};

/// Descriptor for `Source`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sourceDescriptor = $convert.base64Decode(
    'CgZTb3VyY2USFgoSU09VUkNFX1VOU1BFQ0lGSUVEEAASEQoNU09VUkNFX1NDUkVFThABEhEKDV'
    'NPVVJDRV9DQU1FUkEQAg==');

@$core.Deprecated('Use cameraLensDescriptor instead')
const CameraLens$json = {
  '1': 'CameraLens',
  '2': [
    {'1': 'CAMERA_LENS_UNSPECIFIED', '2': 0},
    {'1': 'CAMERA_LENS_BACK', '2': 1},
    {'1': 'CAMERA_LENS_FRONT', '2': 2},
  ],
};

/// Descriptor for `CameraLens`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List cameraLensDescriptor = $convert.base64Decode(
    'CgpDYW1lcmFMZW5zEhsKF0NBTUVSQV9MRU5TX1VOU1BFQ0lGSUVEEAASFAoQQ0FNRVJBX0xFTl'
    'NfQkFDSxABEhUKEUNBTUVSQV9MRU5TX0ZST05UEAI=');

@$core.Deprecated('Use audioAnswerDescriptor instead')
const AudioAnswer$json = {
  '1': 'AudioAnswer',
  '2': [
    {'1': 'AUDIO_ANSWER_UNSPECIFIED', '2': 0},
    {'1': 'AUDIO_ANSWER_SENDING', '2': 1},
    {'1': 'AUDIO_ANSWER_OFF', '2': 2},
    {'1': 'AUDIO_ANSWER_UNSUPPORTED', '2': 3},
  ],
};

/// Descriptor for `AudioAnswer`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List audioAnswerDescriptor = $convert.base64Decode(
    'CgtBdWRpb0Fuc3dlchIcChhBVURJT19BTlNXRVJfVU5TUEVDSUZJRUQQABIYChRBVURJT19BTl'
    'NXRVJfU0VORElORxABEhQKEEFVRElPX0FOU1dFUl9PRkYQAhIcChhBVURJT19BTlNXRVJfVU5T'
    'VVBQT1JURUQQAw==');

@$core.Deprecated('Use denyReasonDescriptor instead')
const DenyReason$json = {
  '1': 'DenyReason',
  '2': [
    {'1': 'DENY_REASON_UNSPECIFIED', '2': 0},
    {'1': 'DENY_REASON_DENIED', '2': 1},
    {'1': 'DENY_REASON_TIMEOUT', '2': 2},
    {'1': 'DENY_REASON_BUSY', '2': 3},
    {'1': 'DENY_REASON_UNSUPPORTED', '2': 4},
    {'1': 'DENY_REASON_TURNED_OFF', '2': 5},
    {'1': 'DENY_REASON_VERSION', '2': 6},
    {'1': 'DENY_REASON_NO_CODEC', '2': 7},
    {'1': 'DENY_REASON_CANNOT_ASK', '2': 8},
    {'1': 'DENY_REASON_FAILED', '2': 9},
  ],
};

/// Descriptor for `DenyReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List denyReasonDescriptor = $convert.base64Decode(
    'CgpEZW55UmVhc29uEhsKF0RFTllfUkVBU09OX1VOU1BFQ0lGSUVEEAASFgoSREVOWV9SRUFTT0'
    '5fREVOSUVEEAESFwoTREVOWV9SRUFTT05fVElNRU9VVBACEhQKEERFTllfUkVBU09OX0JVU1kQ'
    'AxIbChdERU5ZX1JFQVNPTl9VTlNVUFBPUlRFRBAEEhoKFkRFTllfUkVBU09OX1RVUk5FRF9PRk'
    'YQBRIXChNERU5ZX1JFQVNPTl9WRVJTSU9OEAYSGAoUREVOWV9SRUFTT05fTk9fQ09ERUMQBxIa'
    'ChZERU5ZX1JFQVNPTl9DQU5OT1RfQVNLEAgSFgoSREVOWV9SRUFTT05fRkFJTEVEEAk=');

@$core.Deprecated('Use stopReasonDescriptor instead')
const StopReason$json = {
  '1': 'StopReason',
  '2': [
    {'1': 'STOP_REASON_UNSPECIFIED', '2': 0},
    {'1': 'STOP_REASON_VIEWER_DONE', '2': 1},
    {'1': 'STOP_REASON_STOPPED_ON_SOURCE', '2': 2},
    {'1': 'STOP_REASON_SYSTEM_ENDED', '2': 3},
    {'1': 'STOP_REASON_TURNED_OFF', '2': 4},
    {'1': 'STOP_REASON_FAILED', '2': 5},
    {'1': 'STOP_REASON_NOT_MIRRORING', '2': 6},
  ],
};

/// Descriptor for `StopReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List stopReasonDescriptor = $convert.base64Decode(
    'CgpTdG9wUmVhc29uEhsKF1NUT1BfUkVBU09OX1VOU1BFQ0lGSUVEEAASGwoXU1RPUF9SRUFTT0'
    '5fVklFV0VSX0RPTkUQARIhCh1TVE9QX1JFQVNPTl9TVE9QUEVEX09OX1NPVVJDRRACEhwKGFNU'
    'T1BfUkVBU09OX1NZU1RFTV9FTkRFRBADEhoKFlNUT1BfUkVBU09OX1RVUk5FRF9PRkYQBBIWCh'
    'JTVE9QX1JFQVNPTl9GQUlMRUQQBRIdChlTVE9QX1JFQVNPTl9OT1RfTUlSUk9SSU5HEAY=');

@$core.Deprecated('Use cameraOptionsDescriptor instead')
const CameraOptions$json = {
  '1': 'CameraOptions',
  '2': [
    {
      '1': 'lens',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.CameraLens',
      '10': 'lens'
    },
  ],
};

/// Descriptor for `CameraOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraOptionsDescriptor = $convert.base64Decode(
    'Cg1DYW1lcmFPcHRpb25zEjMKBGxlbnMYASABKA4yHy5mZXJyZXQubWlycm9yaW5nLnYxLkNhbW'
    'VyYUxlbnNSBGxlbnM=');

@$core.Deprecated('Use startRequestDescriptor instead')
const StartRequest$json = {
  '1': 'StartRequest',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 13, '10': 'version'},
    {
      '1': 'codecs',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.ferret.mirroring.v1.Codec',
      '10': 'codecs'
    },
    {'1': 'max_width', '3': 3, '4': 1, '5': 13, '10': 'maxWidth'},
    {'1': 'max_height', '3': 4, '4': 1, '5': 13, '10': 'maxHeight'},
    {'1': 'max_fps', '3': 5, '4': 1, '5': 13, '10': 'maxFps'},
    {
      '1': 'audio_codecs',
      '3': 6,
      '4': 3,
      '5': 14,
      '6': '.ferret.mirroring.v1.AudioCodec',
      '10': 'audioCodecs'
    },
    {
      '1': 'source',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.Source',
      '10': 'source'
    },
    {
      '1': 'camera',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.ferret.mirroring.v1.CameraOptions',
      '10': 'camera'
    },
  ],
};

/// Descriptor for `StartRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startRequestDescriptor = $convert.base64Decode(
    'CgxTdGFydFJlcXVlc3QSGAoHdmVyc2lvbhgBIAEoDVIHdmVyc2lvbhIyCgZjb2RlY3MYAiADKA'
    '4yGi5mZXJyZXQubWlycm9yaW5nLnYxLkNvZGVjUgZjb2RlY3MSGwoJbWF4X3dpZHRoGAMgASgN'
    'UghtYXhXaWR0aBIdCgptYXhfaGVpZ2h0GAQgASgNUgltYXhIZWlnaHQSFwoHbWF4X2ZwcxgFIA'
    'EoDVIGbWF4RnBzEkIKDGF1ZGlvX2NvZGVjcxgGIAMoDjIfLmZlcnJldC5taXJyb3JpbmcudjEu'
    'QXVkaW9Db2RlY1ILYXVkaW9Db2RlY3MSMwoGc291cmNlGAcgASgOMhsuZmVycmV0Lm1pcnJvcm'
    'luZy52MS5Tb3VyY2VSBnNvdXJjZRI6CgZjYW1lcmEYCCABKAsyIi5mZXJyZXQubWlycm9yaW5n'
    'LnYxLkNhbWVyYU9wdGlvbnNSBmNhbWVyYQ==');

@$core.Deprecated('Use startPendingDescriptor instead')
const StartPending$json = {
  '1': 'StartPending',
  '2': [
    {'1': 'timeout_seconds', '3': 1, '4': 1, '5': 13, '10': 'timeoutSeconds'},
  ],
};

/// Descriptor for `StartPending`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startPendingDescriptor = $convert.base64Decode(
    'CgxTdGFydFBlbmRpbmcSJwoPdGltZW91dF9zZWNvbmRzGAEgASgNUg50aW1lb3V0U2Vjb25kcw'
    '==');

@$core.Deprecated('Use startAcceptDescriptor instead')
const StartAccept$json = {
  '1': 'StartAccept',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 13, '10': 'version'},
    {
      '1': 'codec',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.Codec',
      '10': 'codec'
    },
    {
      '1': 'audio',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.AudioAnswer',
      '10': 'audio'
    },
    {
      '1': 'audio_codec',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.AudioCodec',
      '10': 'audioCodec'
    },
  ],
};

/// Descriptor for `StartAccept`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startAcceptDescriptor = $convert.base64Decode(
    'CgtTdGFydEFjY2VwdBIYCgd2ZXJzaW9uGAEgASgNUgd2ZXJzaW9uEjAKBWNvZGVjGAIgASgOMh'
    'ouZmVycmV0Lm1pcnJvcmluZy52MS5Db2RlY1IFY29kZWMSNgoFYXVkaW8YAyABKA4yIC5mZXJy'
    'ZXQubWlycm9yaW5nLnYxLkF1ZGlvQW5zd2VyUgVhdWRpbxJACgthdWRpb19jb2RlYxgEIAEoDj'
    'IfLmZlcnJldC5taXJyb3JpbmcudjEuQXVkaW9Db2RlY1IKYXVkaW9Db2RlYw==');

@$core.Deprecated('Use startDenyDescriptor instead')
const StartDeny$json = {
  '1': 'StartDeny',
  '2': [
    {
      '1': 'reason',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.DenyReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `StartDeny`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startDenyDescriptor = $convert.base64Decode(
    'CglTdGFydERlbnkSNwoGcmVhc29uGAEgASgOMh8uZmVycmV0Lm1pcnJvcmluZy52MS5EZW55Um'
    'Vhc29uUgZyZWFzb24=');

@$core.Deprecated('Use streamConfigDescriptor instead')
const StreamConfig$json = {
  '1': 'StreamConfig',
  '2': [
    {'1': 'config_id', '3': 1, '4': 1, '5': 13, '10': 'configId'},
    {
      '1': 'codec',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.Codec',
      '10': 'codec'
    },
    {'1': 'width', '3': 3, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 13, '10': 'height'},
    {'1': 'rotation', '3': 5, '4': 1, '5': 13, '10': 'rotation'},
    {'1': 'fps', '3': 6, '4': 1, '5': 13, '10': 'fps'},
    {'1': 'sps', '3': 7, '4': 1, '5': 12, '10': 'sps'},
    {'1': 'pps', '3': 8, '4': 1, '5': 12, '10': 'pps'},
    {'1': 'turn', '3': 9, '4': 1, '5': 13, '10': 'turn'},
  ],
};

/// Descriptor for `StreamConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamConfigDescriptor = $convert.base64Decode(
    'CgxTdHJlYW1Db25maWcSGwoJY29uZmlnX2lkGAEgASgNUghjb25maWdJZBIwCgVjb2RlYxgCIA'
    'EoDjIaLmZlcnJldC5taXJyb3JpbmcudjEuQ29kZWNSBWNvZGVjEhQKBXdpZHRoGAMgASgNUgV3'
    'aWR0aBIWCgZoZWlnaHQYBCABKA1SBmhlaWdodBIaCghyb3RhdGlvbhgFIAEoDVIIcm90YXRpb2'
    '4SEAoDZnBzGAYgASgNUgNmcHMSEAoDc3BzGAcgASgMUgNzcHMSEAoDcHBzGAggASgMUgNwcHMS'
    'EgoEdHVybhgJIAEoDVIEdHVybg==');

@$core.Deprecated('Use frameDescriptor instead')
const Frame$json = {
  '1': 'Frame',
  '2': [
    {'1': 'config_id', '3': 1, '4': 1, '5': 13, '10': 'configId'},
    {'1': 'sequence', '3': 2, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'pts_us', '3': 3, '4': 1, '5': 3, '10': 'ptsUs'},
    {'1': 'keyframe', '3': 4, '4': 1, '5': 8, '10': 'keyframe'},
    {'1': 'data', '3': 5, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `Frame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List frameDescriptor = $convert.base64Decode(
    'CgVGcmFtZRIbCgljb25maWdfaWQYASABKA1SCGNvbmZpZ0lkEhoKCHNlcXVlbmNlGAIgASgEUg'
    'hzZXF1ZW5jZRIVCgZwdHNfdXMYAyABKANSBXB0c1VzEhoKCGtleWZyYW1lGAQgASgIUghrZXlm'
    'cmFtZRISCgRkYXRhGAUgASgMUgRkYXRh');

@$core.Deprecated('Use audioConfigDescriptor instead')
const AudioConfig$json = {
  '1': 'AudioConfig',
  '2': [
    {
      '1': 'codec',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.AudioCodec',
      '10': 'codec'
    },
    {'1': 'sample_rate', '3': 2, '4': 1, '5': 13, '10': 'sampleRate'},
    {'1': 'channels', '3': 3, '4': 1, '5': 13, '10': 'channels'},
  ],
};

/// Descriptor for `AudioConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioConfigDescriptor = $convert.base64Decode(
    'CgtBdWRpb0NvbmZpZxI1CgVjb2RlYxgBIAEoDjIfLmZlcnJldC5taXJyb3JpbmcudjEuQXVkaW'
    '9Db2RlY1IFY29kZWMSHwoLc2FtcGxlX3JhdGUYAiABKA1SCnNhbXBsZVJhdGUSGgoIY2hhbm5l'
    'bHMYAyABKA1SCGNoYW5uZWxz');

@$core.Deprecated('Use audioFrameDescriptor instead')
const AudioFrame$json = {
  '1': 'AudioFrame',
  '2': [
    {'1': 'sequence', '3': 1, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'pts_us', '3': 2, '4': 1, '5': 3, '10': 'ptsUs'},
    {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `AudioFrame`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioFrameDescriptor = $convert.base64Decode(
    'CgpBdWRpb0ZyYW1lEhoKCHNlcXVlbmNlGAEgASgEUghzZXF1ZW5jZRIVCgZwdHNfdXMYAiABKA'
    'NSBXB0c1VzEhIKBGRhdGEYAyABKAxSBGRhdGE=');

@$core.Deprecated('Use audioEndedDescriptor instead')
const AudioEnded$json = {
  '1': 'AudioEnded',
};

/// Descriptor for `AudioEnded`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List audioEndedDescriptor =
    $convert.base64Decode('CgpBdWRpb0VuZGVk');

@$core.Deprecated('Use cameraStateDescriptor instead')
const CameraState$json = {
  '1': 'CameraState',
  '2': [
    {
      '1': 'lens',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.CameraLens',
      '10': 'lens'
    },
    {
      '1': 'lenses',
      '3': 2,
      '4': 3,
      '5': 14,
      '6': '.ferret.mirroring.v1.CameraLens',
      '10': 'lenses'
    },
  ],
};

/// Descriptor for `CameraState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraStateDescriptor = $convert.base64Decode(
    'CgtDYW1lcmFTdGF0ZRIzCgRsZW5zGAEgASgOMh8uZmVycmV0Lm1pcnJvcmluZy52MS5DYW1lcm'
    'FMZW5zUgRsZW5zEjcKBmxlbnNlcxgCIAMoDjIfLmZlcnJldC5taXJyb3JpbmcudjEuQ2FtZXJh'
    'TGVuc1IGbGVuc2Vz');

@$core.Deprecated('Use cameraSwitchDescriptor instead')
const CameraSwitch$json = {
  '1': 'CameraSwitch',
  '2': [
    {
      '1': 'lens',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.CameraLens',
      '10': 'lens'
    },
  ],
};

/// Descriptor for `CameraSwitch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cameraSwitchDescriptor = $convert.base64Decode(
    'CgxDYW1lcmFTd2l0Y2gSMwoEbGVucxgBIAEoDjIfLmZlcnJldC5taXJyb3JpbmcudjEuQ2FtZX'
    'JhTGVuc1IEbGVucw==');

@$core.Deprecated('Use keyframeRequestDescriptor instead')
const KeyframeRequest$json = {
  '1': 'KeyframeRequest',
};

/// Descriptor for `KeyframeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyframeRequestDescriptor =
    $convert.base64Decode('Cg9LZXlmcmFtZVJlcXVlc3Q=');

@$core.Deprecated('Use stopDescriptor instead')
const Stop$json = {
  '1': 'Stop',
  '2': [
    {
      '1': 'reason',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.mirroring.v1.StopReason',
      '10': 'reason'
    },
  ],
};

/// Descriptor for `Stop`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stopDescriptor = $convert.base64Decode(
    'CgRTdG9wEjcKBnJlYXNvbhgBIAEoDjIfLmZlcnJldC5taXJyb3JpbmcudjEuU3RvcFJlYXNvbl'
    'IGcmVhc29u');

@$core.Deprecated('Use sourceStateDescriptor instead')
const SourceState$json = {
  '1': 'SourceState',
  '2': [
    {'1': 'screen_off', '3': 1, '4': 1, '5': 8, '10': 'screenOff'},
  ],
};

/// Descriptor for `SourceState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sourceStateDescriptor = $convert.base64Decode(
    'CgtTb3VyY2VTdGF0ZRIdCgpzY3JlZW5fb2ZmGAEgASgIUglzY3JlZW5PZmY=');

@$core.Deprecated('Use statsDescriptor instead')
const Stats$json = {
  '1': 'Stats',
  '2': [
    {'1': 'sent_at_ms', '3': 1, '4': 1, '5': 3, '10': 'sentAtMs'},
    {'1': 'echo_sent_at_ms', '3': 2, '4': 1, '5': 3, '10': 'echoSentAtMs'},
    {'1': 'fps', '3': 3, '4': 1, '5': 13, '10': 'fps'},
    {'1': 'dropped_frames', '3': 4, '4': 1, '5': 13, '10': 'droppedFrames'},
    {'1': 'bitrate_kbps', '3': 5, '4': 1, '5': 13, '10': 'bitrateKbps'},
  ],
};

/// Descriptor for `Stats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statsDescriptor = $convert.base64Decode(
    'CgVTdGF0cxIcCgpzZW50X2F0X21zGAEgASgDUghzZW50QXRNcxIlCg9lY2hvX3NlbnRfYXRfbX'
    'MYAiABKANSDGVjaG9TZW50QXRNcxIQCgNmcHMYAyABKA1SA2ZwcxIlCg5kcm9wcGVkX2ZyYW1l'
    'cxgEIAEoDVINZHJvcHBlZEZyYW1lcxIhCgxiaXRyYXRlX2ticHMYBSABKA1SC2JpdHJhdGVLYn'
    'Bz');
