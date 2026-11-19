// This is a generated file - do not edit.
//
// Generated from ferret/scripting/v1/scripting.proto.

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

@$core.Deprecated('Use scriptNoticeResultDescriptor instead')
const ScriptNoticeResult$json = {
  '1': 'ScriptNoticeResult',
  '2': [
    {'1': 'SCRIPT_NOTICE_RESULT_UNSPECIFIED', '2': 0},
    {'1': 'SCRIPT_NOTICE_RESULT_SHOWN', '2': 1},
    {'1': 'SCRIPT_NOTICE_RESULT_NOT_ALLOWED', '2': 2},
    {'1': 'SCRIPT_NOTICE_RESULT_TOO_MANY', '2': 3},
    {'1': 'SCRIPT_NOTICE_RESULT_EMPTY', '2': 4},
  ],
};

/// Descriptor for `ScriptNoticeResult`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List scriptNoticeResultDescriptor = $convert.base64Decode(
    'ChJTY3JpcHROb3RpY2VSZXN1bHQSJAogU0NSSVBUX05PVElDRV9SRVNVTFRfVU5TUEVDSUZJRU'
    'QQABIeChpTQ1JJUFRfTk9USUNFX1JFU1VMVF9TSE9XThABEiQKIFNDUklQVF9OT1RJQ0VfUkVT'
    'VUxUX05PVF9BTExPV0VEEAISIQodU0NSSVBUX05PVElDRV9SRVNVTFRfVE9PX01BTlkQAxIeCh'
    'pTQ1JJUFRfTk9USUNFX1JFU1VMVF9FTVBUWRAE');

@$core.Deprecated('Use scriptNoticeDescriptor instead')
const ScriptNotice$json = {
  '1': 'ScriptNotice',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'body', '3': 2, '4': 1, '5': 9, '10': 'body'},
  ],
};

/// Descriptor for `ScriptNotice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scriptNoticeDescriptor = $convert.base64Decode(
    'CgxTY3JpcHROb3RpY2USFAoFdGl0bGUYASABKAlSBXRpdGxlEhIKBGJvZHkYAiABKAlSBGJvZH'
    'k=');

@$core.Deprecated('Use scriptNoticeReplyDescriptor instead')
const ScriptNoticeReply$json = {
  '1': 'ScriptNoticeReply',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.ferret.scripting.v1.ScriptNoticeResult',
      '10': 'result'
    },
  ],
};

/// Descriptor for `ScriptNoticeReply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scriptNoticeReplyDescriptor = $convert.base64Decode(
    'ChFTY3JpcHROb3RpY2VSZXBseRI/CgZyZXN1bHQYASABKA4yJy5mZXJyZXQuc2NyaXB0aW5nLn'
    'YxLlNjcmlwdE5vdGljZVJlc3VsdFIGcmVzdWx0');
