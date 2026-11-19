// This is a generated file - do not edit.
//
// Generated from ferret/photos/v1/photos.proto.

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

@$core.Deprecated('Use photoKindDescriptor instead')
const PhotoKind$json = {
  '1': 'PhotoKind',
  '2': [
    {'1': 'PHOTO_KIND_UNSPECIFIED', '2': 0},
    {'1': 'PHOTO_KIND_PHOTO', '2': 1},
    {'1': 'PHOTO_KIND_SCREENSHOT', '2': 2},
    {'1': 'PHOTO_KIND_VIDEO', '2': 3},
  ],
};

/// Descriptor for `PhotoKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List photoKindDescriptor = $convert.base64Decode(
    'CglQaG90b0tpbmQSGgoWUEhPVE9fS0lORF9VTlNQRUNJRklFRBAAEhQKEFBIT1RPX0tJTkRfUE'
    'hPVE8QARIZChVQSE9UT19LSU5EX1NDUkVFTlNIT1QQAhIUChBQSE9UT19LSU5EX1ZJREVPEAM=');

@$core.Deprecated('Use photoAccessDescriptor instead')
const PhotoAccess$json = {
  '1': 'PhotoAccess',
  '2': [
    {'1': 'PHOTO_ACCESS_UNSPECIFIED', '2': 0},
    {'1': 'PHOTO_ACCESS_NOT_ALLOWED', '2': 1},
    {'1': 'PHOTO_ACCESS_NO_PERMISSION', '2': 2},
    {'1': 'PHOTO_ACCESS_LIMITED', '2': 3},
    {'1': 'PHOTO_ACCESS_FULL', '2': 4},
    {'1': 'PHOTO_ACCESS_UNAVAILABLE', '2': 5},
  ],
};

/// Descriptor for `PhotoAccess`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List photoAccessDescriptor = $convert.base64Decode(
    'CgtQaG90b0FjY2VzcxIcChhQSE9UT19BQ0NFU1NfVU5TUEVDSUZJRUQQABIcChhQSE9UT19BQ0'
    'NFU1NfTk9UX0FMTE9XRUQQARIeChpQSE9UT19BQ0NFU1NfTk9fUEVSTUlTU0lPThACEhgKFFBI'
    'T1RPX0FDQ0VTU19MSU1JVEVEEAMSFQoRUEhPVE9fQUNDRVNTX0ZVTEwQBBIcChhQSE9UT19BQ0'
    'NFU1NfVU5BVkFJTEFCTEUQBQ==');

@$core.Deprecated('Use photoItemDescriptor instead')
const PhotoItem$json = {
  '1': 'PhotoItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'taken_at_ms', '3': 2, '4': 1, '5': 3, '10': 'takenAtMs'},
    {'1': 'width', '3': 3, '4': 1, '5': 13, '10': 'width'},
    {'1': 'height', '3': 4, '4': 1, '5': 13, '10': 'height'},
    {
      '1': 'kind',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.ferret.photos.v1.PhotoKind',
      '10': 'kind'
    },
    {'1': 'size', '3': 6, '4': 1, '5': 4, '10': 'size'},
    {'1': 'name', '3': 7, '4': 1, '5': 9, '10': 'name'},
    {'1': 'duration_ms', '3': 8, '4': 1, '5': 13, '10': 'durationMs'},
  ],
};

/// Descriptor for `PhotoItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoItemDescriptor = $convert.base64Decode(
    'CglQaG90b0l0ZW0SDgoCaWQYASABKAlSAmlkEh4KC3Rha2VuX2F0X21zGAIgASgDUgl0YWtlbk'
    'F0TXMSFAoFd2lkdGgYAyABKA1SBXdpZHRoEhYKBmhlaWdodBgEIAEoDVIGaGVpZ2h0Ei8KBGtp'
    'bmQYBSABKA4yGy5mZXJyZXQucGhvdG9zLnYxLlBob3RvS2luZFIEa2luZBISCgRzaXplGAYgAS'
    'gEUgRzaXplEhIKBG5hbWUYByABKAlSBG5hbWUSHwoLZHVyYXRpb25fbXMYCCABKA1SCmR1cmF0'
    'aW9uTXM=');

@$core.Deprecated('Use photoListRequestDescriptor instead')
const PhotoListRequest$json = {
  '1': 'PhotoListRequest',
  '2': [
    {'1': 'cursor', '3': 1, '4': 1, '5': 9, '10': 'cursor'},
    {'1': 'limit', '3': 2, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `PhotoListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoListRequestDescriptor = $convert.base64Decode(
    'ChBQaG90b0xpc3RSZXF1ZXN0EhYKBmN1cnNvchgBIAEoCVIGY3Vyc29yEhQKBWxpbWl0GAIgAS'
    'gNUgVsaW1pdA==');

@$core.Deprecated('Use photoListDescriptor instead')
const PhotoList$json = {
  '1': 'PhotoList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.photos.v1.PhotoItem',
      '10': 'items'
    },
    {'1': 'next_cursor', '3': 2, '4': 1, '5': 9, '10': 'nextCursor'},
    {
      '1': 'access',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.ferret.photos.v1.PhotoAccess',
      '10': 'access'
    },
    {'1': 'total', '3': 4, '4': 1, '5': 13, '10': 'total'},
  ],
};

/// Descriptor for `PhotoList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoListDescriptor = $convert.base64Decode(
    'CglQaG90b0xpc3QSMQoFaXRlbXMYASADKAsyGy5mZXJyZXQucGhvdG9zLnYxLlBob3RvSXRlbV'
    'IFaXRlbXMSHwoLbmV4dF9jdXJzb3IYAiABKAlSCm5leHRDdXJzb3ISNQoGYWNjZXNzGAMgASgO'
    'Mh0uZmVycmV0LnBob3Rvcy52MS5QaG90b0FjY2Vzc1IGYWNjZXNzEhQKBXRvdGFsGAQgASgNUg'
    'V0b3RhbA==');

@$core.Deprecated('Use thumbnailRequestDescriptor instead')
const ThumbnailRequest$json = {
  '1': 'ThumbnailRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'max_px', '3': 2, '4': 1, '5': 13, '10': 'maxPx'},
  ],
};

/// Descriptor for `ThumbnailRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thumbnailRequestDescriptor = $convert.base64Decode(
    'ChBUaHVtYm5haWxSZXF1ZXN0Eg4KAmlkGAEgASgJUgJpZBIVCgZtYXhfcHgYAiABKA1SBW1heF'
    'B4');

@$core.Deprecated('Use thumbnailDescriptor instead')
const Thumbnail$json = {
  '1': 'Thumbnail',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'jpeg', '3': 2, '4': 1, '5': 12, '10': 'jpeg'},
    {
      '1': 'access',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.ferret.photos.v1.PhotoAccess',
      '10': 'access'
    },
  ],
};

/// Descriptor for `Thumbnail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List thumbnailDescriptor = $convert.base64Decode(
    'CglUaHVtYm5haWwSDgoCaWQYASABKAlSAmlkEhIKBGpwZWcYAiABKAxSBGpwZWcSNQoGYWNjZX'
    'NzGAMgASgOMh0uZmVycmV0LnBob3Rvcy52MS5QaG90b0FjY2Vzc1IGYWNjZXNz');

@$core.Deprecated('Use photoFetchRequestDescriptor instead')
const PhotoFetchRequest$json = {
  '1': 'PhotoFetchRequest',
  '2': [
    {'1': 'ids', '3': 1, '4': 3, '5': 9, '10': 'ids'},
  ],
};

/// Descriptor for `PhotoFetchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoFetchRequestDescriptor = $convert
    .base64Decode('ChFQaG90b0ZldGNoUmVxdWVzdBIQCgNpZHMYASADKAlSA2lkcw==');

@$core.Deprecated('Use photoFetchReplyDescriptor instead')
const PhotoFetchReply$json = {
  '1': 'PhotoFetchReply',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {
      '1': 'access',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.photos.v1.PhotoAccess',
      '10': 'access'
    },
    {'1': 'missing', '3': 3, '4': 1, '5': 13, '10': 'missing'},
  ],
};

/// Descriptor for `PhotoFetchReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoFetchReplyDescriptor = $convert.base64Decode(
    'Cg9QaG90b0ZldGNoUmVwbHkSHwoLdHJhbnNmZXJfaWQYASABKAlSCnRyYW5zZmVySWQSNQoGYW'
    'NjZXNzGAIgASgOMh0uZmVycmV0LnBob3Rvcy52MS5QaG90b0FjY2Vzc1IGYWNjZXNzEhgKB21p'
    'c3NpbmcYAyABKA1SB21pc3Npbmc=');

@$core.Deprecated('Use screenshotSubscriptionDescriptor instead')
const ScreenshotSubscription$json = {
  '1': 'ScreenshotSubscription',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `ScreenshotSubscription`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List screenshotSubscriptionDescriptor =
    $convert.base64Decode(
        'ChZTY3JlZW5zaG90U3Vic2NyaXB0aW9uEhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQ=');

@$core.Deprecated('Use screenshotSentDescriptor instead')
const ScreenshotSent$json = {
  '1': 'ScreenshotSent',
  '2': [
    {'1': 'transfer_id', '3': 1, '4': 1, '5': 9, '10': 'transferId'},
    {
      '1': 'item',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.ferret.photos.v1.PhotoItem',
      '10': 'item'
    },
  ],
};

/// Descriptor for `ScreenshotSent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List screenshotSentDescriptor = $convert.base64Decode(
    'Cg5TY3JlZW5zaG90U2VudBIfCgt0cmFuc2Zlcl9pZBgBIAEoCVIKdHJhbnNmZXJJZBIvCgRpdG'
    'VtGAIgASgLMhsuZmVycmV0LnBob3Rvcy52MS5QaG90b0l0ZW1SBGl0ZW0=');

@$core.Deprecated('Use photoAccessPromptDescriptor instead')
const PhotoAccessPrompt$json = {
  '1': 'PhotoAccessPrompt',
};

/// Descriptor for `PhotoAccessPrompt`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List photoAccessPromptDescriptor =
    $convert.base64Decode('ChFQaG90b0FjY2Vzc1Byb21wdA==');
