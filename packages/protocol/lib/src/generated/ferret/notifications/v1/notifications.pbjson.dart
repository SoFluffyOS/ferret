// This is a generated file - do not edit.
//
// Generated from ferret/notifications/v1/notifications.proto.

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

@$core.Deprecated('Use appFilterDescriptor instead')
const AppFilter$json = {
  '1': 'AppFilter',
  '2': [
    {'1': 'APP_FILTER_UNSPECIFIED', '2': 0},
    {'1': 'APP_FILTER_ALL', '2': 1},
    {'1': 'APP_FILTER_ALL_EXCEPT', '2': 2},
    {'1': 'APP_FILTER_ONLY', '2': 3},
  ],
};

/// Descriptor for `AppFilter`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List appFilterDescriptor = $convert.base64Decode(
    'CglBcHBGaWx0ZXISGgoWQVBQX0ZJTFRFUl9VTlNQRUNJRklFRBAAEhIKDkFQUF9GSUxURVJfQU'
    'xMEAESGQoVQVBQX0ZJTFRFUl9BTExfRVhDRVBUEAISEwoPQVBQX0ZJTFRFUl9PTkxZEAM=');

@$core.Deprecated('Use notificationActionDescriptor instead')
const NotificationAction$json = {
  '1': 'NotificationAction',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'is_reply', '3': 3, '4': 1, '5': 8, '10': 'isReply'},
  ],
};

/// Descriptor for `NotificationAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notificationActionDescriptor = $convert.base64Decode(
    'ChJOb3RpZmljYXRpb25BY3Rpb24SDgoCaWQYASABKAlSAmlkEhQKBXRpdGxlGAIgASgJUgV0aX'
    'RsZRIZCghpc19yZXBseRgDIAEoCFIHaXNSZXBseQ==');

@$core.Deprecated('Use notificationItemDescriptor instead')
const NotificationItem$json = {
  '1': 'NotificationItem',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'app_package', '3': 2, '4': 1, '5': 9, '10': 'appPackage'},
    {'1': 'app_name', '3': 3, '4': 1, '5': 9, '10': 'appName'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'text', '3': 5, '4': 1, '5': 9, '10': 'text'},
    {'1': 'posted_at_ms', '3': 6, '4': 1, '5': 3, '10': 'postedAtMs'},
    {'1': 'app_icon_png', '3': 7, '4': 1, '5': 12, '10': 'appIconPng'},
    {'1': 'is_conversation', '3': 8, '4': 1, '5': 8, '10': 'isConversation'},
    {
      '1': 'actions',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.ferret.notifications.v1.NotificationAction',
      '10': 'actions'
    },
  ],
};

/// Descriptor for `NotificationItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notificationItemDescriptor = $convert.base64Decode(
    'ChBOb3RpZmljYXRpb25JdGVtEhAKA2tleRgBIAEoCVIDa2V5Eh8KC2FwcF9wYWNrYWdlGAIgAS'
    'gJUgphcHBQYWNrYWdlEhkKCGFwcF9uYW1lGAMgASgJUgdhcHBOYW1lEhQKBXRpdGxlGAQgASgJ'
    'UgV0aXRsZRISCgR0ZXh0GAUgASgJUgR0ZXh0EiAKDHBvc3RlZF9hdF9tcxgGIAEoA1IKcG9zdG'
    'VkQXRNcxIgCgxhcHBfaWNvbl9wbmcYByABKAxSCmFwcEljb25QbmcSJwoPaXNfY29udmVyc2F0'
    'aW9uGAggASgIUg5pc0NvbnZlcnNhdGlvbhJFCgdhY3Rpb25zGAkgAygLMisuZmVycmV0Lm5vdG'
    'lmaWNhdGlvbnMudjEuTm90aWZpY2F0aW9uQWN0aW9uUgdhY3Rpb25z');

@$core.Deprecated('Use notificationPostedDescriptor instead')
const NotificationPosted$json = {
  '1': 'NotificationPosted',
  '2': [
    {
      '1': 'notification',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.ferret.notifications.v1.NotificationItem',
      '10': 'notification'
    },
  ],
};

/// Descriptor for `NotificationPosted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notificationPostedDescriptor = $convert.base64Decode(
    'ChJOb3RpZmljYXRpb25Qb3N0ZWQSTQoMbm90aWZpY2F0aW9uGAEgASgLMikuZmVycmV0Lm5vdG'
    'lmaWNhdGlvbnMudjEuTm90aWZpY2F0aW9uSXRlbVIMbm90aWZpY2F0aW9u');

@$core.Deprecated('Use notificationRemovedDescriptor instead')
const NotificationRemoved$json = {
  '1': 'NotificationRemoved',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
  ],
};

/// Descriptor for `NotificationRemoved`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notificationRemovedDescriptor = $convert
    .base64Decode('ChNOb3RpZmljYXRpb25SZW1vdmVkEhAKA2tleRgBIAEoCVIDa2V5');

@$core.Deprecated('Use catchUpDescriptor instead')
const CatchUp$json = {
  '1': 'CatchUp',
  '2': [
    {'1': 'missed_count', '3': 1, '4': 1, '5': 13, '10': 'missedCount'},
    {'1': 'active_keys', '3': 2, '4': 3, '5': 9, '10': 'activeKeys'},
    {'1': 'missed_app_names', '3': 3, '4': 3, '5': 9, '10': 'missedAppNames'},
  ],
};

/// Descriptor for `CatchUp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List catchUpDescriptor = $convert.base64Decode(
    'CgdDYXRjaFVwEiEKDG1pc3NlZF9jb3VudBgBIAEoDVILbWlzc2VkQ291bnQSHwoLYWN0aXZlX2'
    'tleXMYAiADKAlSCmFjdGl2ZUtleXMSKAoQbWlzc2VkX2FwcF9uYW1lcxgDIAMoCVIObWlzc2Vk'
    'QXBwTmFtZXM=');

@$core.Deprecated('Use invokeActionDescriptor instead')
const InvokeAction$json = {
  '1': 'InvokeAction',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'action_id', '3': 2, '4': 1, '5': 9, '10': 'actionId'},
    {'1': 'reply_text', '3': 3, '4': 1, '5': 9, '10': 'replyText'},
  ],
};

/// Descriptor for `InvokeAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invokeActionDescriptor = $convert.base64Decode(
    'CgxJbnZva2VBY3Rpb24SEAoDa2V5GAEgASgJUgNrZXkSGwoJYWN0aW9uX2lkGAIgASgJUghhY3'
    'Rpb25JZBIdCgpyZXBseV90ZXh0GAMgASgJUglyZXBseVRleHQ=');

@$core.Deprecated('Use invokeActionResultDescriptor instead')
const InvokeActionResult$json = {
  '1': 'InvokeActionResult',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
  ],
};

/// Descriptor for `InvokeActionResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invokeActionResultDescriptor =
    $convert.base64Decode('ChJJbnZva2VBY3Rpb25SZXN1bHQSDgoCb2sYASABKAhSAm9r');

@$core.Deprecated('Use dismissNotificationDescriptor instead')
const DismissNotification$json = {
  '1': 'DismissNotification',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
  ],
};

/// Descriptor for `DismissNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dismissNotificationDescriptor = $convert
    .base64Decode('ChNEaXNtaXNzTm90aWZpY2F0aW9uEhAKA2tleRgBIAEoCVIDa2V5');

@$core.Deprecated('Use mirrorSettingsDescriptor instead')
const MirrorSettings$json = {
  '1': 'MirrorSettings',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'access_granted', '3': 2, '4': 1, '5': 8, '10': 'accessGranted'},
    {'1': 'skip_while_using', '3': 3, '4': 1, '5': 8, '10': 'skipWhileUsing'},
    {'1': 'allowed_packages', '3': 4, '4': 3, '5': 9, '10': 'allowedPackages'},
    {
      '1': 'app_filter',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.ferret.notifications.v1.AppFilter',
      '10': 'appFilter'
    },
    {
      '1': 'excluded_packages',
      '3': 6,
      '4': 3,
      '5': 9,
      '10': 'excludedPackages'
    },
  ],
};

/// Descriptor for `MirrorSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mirrorSettingsDescriptor = $convert.base64Decode(
    'Cg5NaXJyb3JTZXR0aW5ncxIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEiUKDmFjY2Vzc19ncm'
    'FudGVkGAIgASgIUg1hY2Nlc3NHcmFudGVkEigKEHNraXBfd2hpbGVfdXNpbmcYAyABKAhSDnNr'
    'aXBXaGlsZVVzaW5nEikKEGFsbG93ZWRfcGFja2FnZXMYBCADKAlSD2FsbG93ZWRQYWNrYWdlcx'
    'JBCgphcHBfZmlsdGVyGAUgASgOMiIuZmVycmV0Lm5vdGlmaWNhdGlvbnMudjEuQXBwRmlsdGVy'
    'UglhcHBGaWx0ZXISKwoRZXhjbHVkZWRfcGFja2FnZXMYBiADKAlSEGV4Y2x1ZGVkUGFja2FnZX'
    'M=');

@$core.Deprecated('Use mirrorSettingsRequestDescriptor instead')
const MirrorSettingsRequest$json = {
  '1': 'MirrorSettingsRequest',
};

/// Descriptor for `MirrorSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mirrorSettingsRequestDescriptor =
    $convert.base64Decode('ChVNaXJyb3JTZXR0aW5nc1JlcXVlc3Q=');

@$core.Deprecated('Use appEntryDescriptor instead')
const AppEntry$json = {
  '1': 'AppEntry',
  '2': [
    {'1': 'package', '3': 1, '4': 1, '5': 9, '10': 'package'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'icon_png', '3': 3, '4': 1, '5': 12, '10': 'iconPng'},
    {'1': 'allowed', '3': 4, '4': 1, '5': 8, '10': 'allowed'},
    {'1': 'is_messaging', '3': 5, '4': 1, '5': 8, '10': 'isMessaging'},
    {'1': 'last_posted_ms', '3': 6, '4': 1, '5': 3, '10': 'lastPostedMs'},
  ],
};

/// Descriptor for `AppEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appEntryDescriptor = $convert.base64Decode(
    'CghBcHBFbnRyeRIYCgdwYWNrYWdlGAEgASgJUgdwYWNrYWdlEhIKBG5hbWUYAiABKAlSBG5hbW'
    'USGQoIaWNvbl9wbmcYAyABKAxSB2ljb25QbmcSGAoHYWxsb3dlZBgEIAEoCFIHYWxsb3dlZBIh'
    'Cgxpc19tZXNzYWdpbmcYBSABKAhSC2lzTWVzc2FnaW5nEiQKDmxhc3RfcG9zdGVkX21zGAYgAS'
    'gDUgxsYXN0UG9zdGVkTXM=');

@$core.Deprecated('Use appListRequestDescriptor instead')
const AppListRequest$json = {
  '1': 'AppListRequest',
};

/// Descriptor for `AppListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appListRequestDescriptor =
    $convert.base64Decode('Cg5BcHBMaXN0UmVxdWVzdA==');

@$core.Deprecated('Use appListResponseDescriptor instead')
const AppListResponse$json = {
  '1': 'AppListResponse',
  '2': [
    {
      '1': 'apps',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.notifications.v1.AppEntry',
      '10': 'apps'
    },
  ],
};

/// Descriptor for `AppListResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appListResponseDescriptor = $convert.base64Decode(
    'Cg9BcHBMaXN0UmVzcG9uc2USNQoEYXBwcxgBIAMoCzIhLmZlcnJldC5ub3RpZmljYXRpb25zLn'
    'YxLkFwcEVudHJ5UgRhcHBz');

@$core.Deprecated('Use appChoiceDescriptor instead')
const AppChoice$json = {
  '1': 'AppChoice',
  '2': [
    {'1': 'package', '3': 1, '4': 1, '5': 9, '10': 'package'},
    {'1': 'allowed', '3': 2, '4': 1, '5': 8, '10': 'allowed'},
  ],
};

/// Descriptor for `AppChoice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appChoiceDescriptor = $convert.base64Decode(
    'CglBcHBDaG9pY2USGAoHcGFja2FnZRgBIAEoCVIHcGFja2FnZRIYCgdhbGxvd2VkGAIgASgIUg'
    'dhbGxvd2Vk');

@$core.Deprecated('Use updateMirrorSettingsDescriptor instead')
const UpdateMirrorSettings$json = {
  '1': 'UpdateMirrorSettings',
  '2': [
    {
      '1': 'apps',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.notifications.v1.AppChoice',
      '10': 'apps'
    },
    {
      '1': 'skip_while_using',
      '3': 2,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'skipWhileUsing',
      '17': true
    },
    {
      '1': 'app_filter',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.ferret.notifications.v1.AppFilter',
      '9': 1,
      '10': 'appFilter',
      '17': true
    },
  ],
  '8': [
    {'1': '_skip_while_using'},
    {'1': '_app_filter'},
  ],
};

/// Descriptor for `UpdateMirrorSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateMirrorSettingsDescriptor = $convert.base64Decode(
    'ChRVcGRhdGVNaXJyb3JTZXR0aW5ncxI2CgRhcHBzGAEgAygLMiIuZmVycmV0Lm5vdGlmaWNhdG'
    'lvbnMudjEuQXBwQ2hvaWNlUgRhcHBzEi0KEHNraXBfd2hpbGVfdXNpbmcYAiABKAhIAFIOc2tp'
    'cFdoaWxlVXNpbmeIAQESRgoKYXBwX2ZpbHRlchgDIAEoDjIiLmZlcnJldC5ub3RpZmljYXRpb2'
    '5zLnYxLkFwcEZpbHRlckgBUglhcHBGaWx0ZXKIAQFCEwoRX3NraXBfd2hpbGVfdXNpbmdCDQoL'
    'X2FwcF9maWx0ZXI=');
