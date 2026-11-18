// This is a generated file - do not edit.
//
// Generated from ferret/messages/v1/messages.proto.

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

@$core.Deprecated('Use messageKindDescriptor instead')
const MessageKind$json = {
  '1': 'MessageKind',
  '2': [
    {'1': 'MESSAGE_KIND_UNSPECIFIED', '2': 0},
    {'1': 'MESSAGE_KIND_INBOX', '2': 1},
    {'1': 'MESSAGE_KIND_SENT', '2': 2},
    {'1': 'MESSAGE_KIND_OUTBOX', '2': 3},
    {'1': 'MESSAGE_KIND_FAILED', '2': 4},
    {'1': 'MESSAGE_KIND_QUEUED', '2': 5},
  ],
};

/// Descriptor for `MessageKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List messageKindDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlS2luZBIcChhNRVNTQUdFX0tJTkRfVU5TUEVDSUZJRUQQABIWChJNRVNTQUdFX0'
    'tJTkRfSU5CT1gQARIVChFNRVNTQUdFX0tJTkRfU0VOVBACEhcKE01FU1NBR0VfS0lORF9PVVRC'
    'T1gQAxIXChNNRVNTQUdFX0tJTkRfRkFJTEVEEAQSFwoTTUVTU0FHRV9LSU5EX1FVRVVFRBAF');

@$core.Deprecated('Use sendFailureDescriptor instead')
const SendFailure$json = {
  '1': 'SendFailure',
  '2': [
    {'1': 'SEND_FAILURE_UNSPECIFIED', '2': 0},
    {'1': 'SEND_FAILURE_NO_ACCESS', '2': 1},
    {'1': 'SEND_FAILURE_NO_RECIPIENT', '2': 2},
    {'1': 'SEND_FAILURE_GROUP', '2': 3},
    {'1': 'SEND_FAILURE_NO_SERVICE', '2': 4},
    {'1': 'SEND_FAILURE_TIMEOUT', '2': 5},
    {'1': 'SEND_FAILURE_OTHER', '2': 6},
  ],
};

/// Descriptor for `SendFailure`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sendFailureDescriptor = $convert.base64Decode(
    'CgtTZW5kRmFpbHVyZRIcChhTRU5EX0ZBSUxVUkVfVU5TUEVDSUZJRUQQABIaChZTRU5EX0ZBSU'
    'xVUkVfTk9fQUNDRVNTEAESHQoZU0VORF9GQUlMVVJFX05PX1JFQ0lQSUVOVBACEhYKElNFTkRf'
    'RkFJTFVSRV9HUk9VUBADEhsKF1NFTkRfRkFJTFVSRV9OT19TRVJWSUNFEAQSGAoUU0VORF9GQU'
    'lMVVJFX1RJTUVPVVQQBRIWChJTRU5EX0ZBSUxVUkVfT1RIRVIQBg==');

@$core.Deprecated('Use participantDescriptor instead')
const Participant$json = {
  '1': 'Participant',
  '2': [
    {'1': 'address', '3': 1, '4': 1, '5': 9, '10': 'address'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'avatar_jpeg', '3': 3, '4': 1, '5': 12, '10': 'avatarJpeg'},
  ],
};

/// Descriptor for `Participant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List participantDescriptor = $convert.base64Decode(
    'CgtQYXJ0aWNpcGFudBIYCgdhZGRyZXNzGAEgASgJUgdhZGRyZXNzEhIKBG5hbWUYAiABKAlSBG'
    '5hbWUSHwoLYXZhdGFyX2pwZWcYAyABKAxSCmF2YXRhckpwZWc=');

@$core.Deprecated('Use conversationDescriptor instead')
const Conversation$json = {
  '1': 'Conversation',
  '2': [
    {'1': 'thread_id', '3': 1, '4': 1, '5': 3, '10': 'threadId'},
    {
      '1': 'participants',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.ferret.messages.v1.Participant',
      '10': 'participants'
    },
    {'1': 'snippet', '3': 3, '4': 1, '5': 9, '10': 'snippet'},
    {'1': 'last_date_ms', '3': 4, '4': 1, '5': 3, '10': 'lastDateMs'},
    {'1': 'unread_count', '3': 5, '4': 1, '5': 13, '10': 'unreadCount'},
    {'1': 'is_group', '3': 6, '4': 1, '5': 8, '10': 'isGroup'},
  ],
};

/// Descriptor for `Conversation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationDescriptor = $convert.base64Decode(
    'CgxDb252ZXJzYXRpb24SGwoJdGhyZWFkX2lkGAEgASgDUgh0aHJlYWRJZBJDCgxwYXJ0aWNpcG'
    'FudHMYAiADKAsyHy5mZXJyZXQubWVzc2FnZXMudjEuUGFydGljaXBhbnRSDHBhcnRpY2lwYW50'
    'cxIYCgdzbmlwcGV0GAMgASgJUgdzbmlwcGV0EiAKDGxhc3RfZGF0ZV9tcxgEIAEoA1IKbGFzdE'
    'RhdGVNcxIhCgx1bnJlYWRfY291bnQYBSABKA1SC3VucmVhZENvdW50EhkKCGlzX2dyb3VwGAYg'
    'ASgIUgdpc0dyb3Vw');

@$core.Deprecated('Use attachmentDescriptor instead')
const Attachment$json = {
  '1': 'Attachment',
  '2': [
    {'1': 'part_id', '3': 1, '4': 1, '5': 9, '10': 'partId'},
    {'1': 'mime', '3': 2, '4': 1, '5': 9, '10': 'mime'},
    {'1': 'size', '3': 3, '4': 1, '5': 3, '10': 'size'},
    {'1': 'thumbnail_jpeg', '3': 4, '4': 1, '5': 12, '10': 'thumbnailJpeg'},
    {'1': 'name', '3': 5, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `Attachment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attachmentDescriptor = $convert.base64Decode(
    'CgpBdHRhY2htZW50EhcKB3BhcnRfaWQYASABKAlSBnBhcnRJZBISCgRtaW1lGAIgASgJUgRtaW'
    '1lEhIKBHNpemUYAyABKANSBHNpemUSJQoOdGh1bWJuYWlsX2pwZWcYBCABKAxSDXRodW1ibmFp'
    'bEpwZWcSEgoEbmFtZRgFIAEoCVIEbmFtZQ==');

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'thread_id', '3': 2, '4': 1, '5': 3, '10': 'threadId'},
    {'1': 'sender_address', '3': 3, '4': 1, '5': 9, '10': 'senderAddress'},
    {'1': 'body', '3': 4, '4': 1, '5': 9, '10': 'body'},
    {'1': 'date_ms', '3': 5, '4': 1, '5': 3, '10': 'dateMs'},
    {
      '1': 'kind',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.ferret.messages.v1.MessageKind',
      '10': 'kind'
    },
    {
      '1': 'attachments',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.ferret.messages.v1.Attachment',
      '10': 'attachments'
    },
    {'1': 'read', '3': 8, '4': 1, '5': 8, '10': 'read'},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEg4KAmlkGAEgASgJUgJpZBIbCgl0aHJlYWRfaWQYAiABKANSCHRocmVhZElkEi'
    'UKDnNlbmRlcl9hZGRyZXNzGAMgASgJUg1zZW5kZXJBZGRyZXNzEhIKBGJvZHkYBCABKAlSBGJv'
    'ZHkSFwoHZGF0ZV9tcxgFIAEoA1IGZGF0ZU1zEjMKBGtpbmQYBiABKA4yHy5mZXJyZXQubWVzc2'
    'FnZXMudjEuTWVzc2FnZUtpbmRSBGtpbmQSQAoLYXR0YWNobWVudHMYByADKAsyHi5mZXJyZXQu'
    'bWVzc2FnZXMudjEuQXR0YWNobWVudFILYXR0YWNobWVudHMSEgoEcmVhZBgIIAEoCFIEcmVhZA'
    '==');

@$core.Deprecated('Use messagesStatusDescriptor instead')
const MessagesStatus$json = {
  '1': 'MessagesStatus',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'sms_access', '3': 2, '4': 1, '5': 8, '10': 'smsAccess'},
    {'1': 'send_access', '3': 3, '4': 1, '5': 8, '10': 'sendAccess'},
    {'1': 'contacts_access', '3': 4, '4': 1, '5': 8, '10': 'contactsAccess'},
  ],
};

/// Descriptor for `MessagesStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messagesStatusDescriptor = $convert.base64Decode(
    'Cg5NZXNzYWdlc1N0YXR1cxIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEh0KCnNtc19hY2Nlc3'
    'MYAiABKAhSCXNtc0FjY2VzcxIfCgtzZW5kX2FjY2VzcxgDIAEoCFIKc2VuZEFjY2VzcxInCg9j'
    'b250YWN0c19hY2Nlc3MYBCABKAhSDmNvbnRhY3RzQWNjZXNz');

@$core.Deprecated('Use statusRequestDescriptor instead')
const StatusRequest$json = {
  '1': 'StatusRequest',
};

/// Descriptor for `StatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusRequestDescriptor =
    $convert.base64Decode('Cg1TdGF0dXNSZXF1ZXN0');

@$core.Deprecated('Use listConversationsDescriptor instead')
const ListConversations$json = {
  '1': 'ListConversations',
  '2': [
    {'1': 'before_date_ms', '3': 1, '4': 1, '5': 3, '10': 'beforeDateMs'},
    {'1': 'limit', '3': 2, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `ListConversations`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConversationsDescriptor = $convert.base64Decode(
    'ChFMaXN0Q29udmVyc2F0aW9ucxIkCg5iZWZvcmVfZGF0ZV9tcxgBIAEoA1IMYmVmb3JlRGF0ZU'
    '1zEhQKBWxpbWl0GAIgASgNUgVsaW1pdA==');

@$core.Deprecated('Use conversationPageDescriptor instead')
const ConversationPage$json = {
  '1': 'ConversationPage',
  '2': [
    {
      '1': 'conversations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.messages.v1.Conversation',
      '10': 'conversations'
    },
    {'1': 'has_more', '3': 2, '4': 1, '5': 8, '10': 'hasMore'},
  ],
};

/// Descriptor for `ConversationPage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List conversationPageDescriptor = $convert.base64Decode(
    'ChBDb252ZXJzYXRpb25QYWdlEkYKDWNvbnZlcnNhdGlvbnMYASADKAsyIC5mZXJyZXQubWVzc2'
    'FnZXMudjEuQ29udmVyc2F0aW9uUg1jb252ZXJzYXRpb25zEhkKCGhhc19tb3JlGAIgASgIUgdo'
    'YXNNb3Jl');

@$core.Deprecated('Use listMessagesDescriptor instead')
const ListMessages$json = {
  '1': 'ListMessages',
  '2': [
    {'1': 'thread_id', '3': 1, '4': 1, '5': 3, '10': 'threadId'},
    {'1': 'before_date_ms', '3': 2, '4': 1, '5': 3, '10': 'beforeDateMs'},
    {'1': 'skip_ids', '3': 3, '4': 3, '5': 9, '10': 'skipIds'},
    {'1': 'limit', '3': 4, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `ListMessages`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listMessagesDescriptor = $convert.base64Decode(
    'CgxMaXN0TWVzc2FnZXMSGwoJdGhyZWFkX2lkGAEgASgDUgh0aHJlYWRJZBIkCg5iZWZvcmVfZG'
    'F0ZV9tcxgCIAEoA1IMYmVmb3JlRGF0ZU1zEhkKCHNraXBfaWRzGAMgAygJUgdza2lwSWRzEhQK'
    'BWxpbWl0GAQgASgNUgVsaW1pdA==');

@$core.Deprecated('Use messagePageDescriptor instead')
const MessagePage$json = {
  '1': 'MessagePage',
  '2': [
    {'1': 'thread_id', '3': 1, '4': 1, '5': 3, '10': 'threadId'},
    {
      '1': 'messages',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.ferret.messages.v1.Message',
      '10': 'messages'
    },
    {'1': 'has_more', '3': 3, '4': 1, '5': 8, '10': 'hasMore'},
  ],
};

/// Descriptor for `MessagePage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messagePageDescriptor = $convert.base64Decode(
    'CgtNZXNzYWdlUGFnZRIbCgl0aHJlYWRfaWQYASABKANSCHRocmVhZElkEjcKCG1lc3NhZ2VzGA'
    'IgAygLMhsuZmVycmV0Lm1lc3NhZ2VzLnYxLk1lc3NhZ2VSCG1lc3NhZ2VzEhkKCGhhc19tb3Jl'
    'GAMgASgIUgdoYXNNb3Jl');

@$core.Deprecated('Use fetchAttachmentDescriptor instead')
const FetchAttachment$json = {
  '1': 'FetchAttachment',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'part_id', '3': 2, '4': 1, '5': 9, '10': 'partId'},
  ],
};

/// Descriptor for `FetchAttachment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchAttachmentDescriptor = $convert.base64Decode(
    'Cg9GZXRjaEF0dGFjaG1lbnQSHQoKbWVzc2FnZV9pZBgBIAEoCVIJbWVzc2FnZUlkEhcKB3Bhcn'
    'RfaWQYAiABKAlSBnBhcnRJZA==');

@$core.Deprecated('Use attachmentDataDescriptor instead')
const AttachmentData$json = {
  '1': 'AttachmentData',
  '2': [
    {'1': 'mime', '3': 1, '4': 1, '5': 9, '10': 'mime'},
    {'1': 'data', '3': 2, '4': 1, '5': 12, '10': 'data'},
  ],
};

/// Descriptor for `AttachmentData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attachmentDataDescriptor = $convert.base64Decode(
    'Cg5BdHRhY2htZW50RGF0YRISCgRtaW1lGAEgASgJUgRtaW1lEhIKBGRhdGEYAiABKAxSBGRhdG'
    'E=');

@$core.Deprecated('Use sendTextDescriptor instead')
const SendText$json = {
  '1': 'SendText',
  '2': [
    {'1': 'thread_id', '3': 1, '4': 1, '5': 3, '10': 'threadId'},
    {'1': 'addresses', '3': 2, '4': 3, '5': 9, '10': 'addresses'},
    {'1': 'text', '3': 3, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `SendText`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendTextDescriptor = $convert.base64Decode(
    'CghTZW5kVGV4dBIbCgl0aHJlYWRfaWQYASABKANSCHRocmVhZElkEhwKCWFkZHJlc3NlcxgCIA'
    'MoCVIJYWRkcmVzc2VzEhIKBHRleHQYAyABKAlSBHRleHQ=');

@$core.Deprecated('Use sendResultDescriptor instead')
const SendResult$json = {
  '1': 'SendResult',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 8, '10': 'ok'},
    {
      '1': 'failure',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.ferret.messages.v1.SendFailure',
      '10': 'failure'
    },
    {'1': 'thread_id', '3': 3, '4': 1, '5': 3, '10': 'threadId'},
  ],
};

/// Descriptor for `SendResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sendResultDescriptor = $convert.base64Decode(
    'CgpTZW5kUmVzdWx0Eg4KAm9rGAEgASgIUgJvaxI5CgdmYWlsdXJlGAIgASgOMh8uZmVycmV0Lm'
    '1lc3NhZ2VzLnYxLlNlbmRGYWlsdXJlUgdmYWlsdXJlEhsKCXRocmVhZF9pZBgDIAEoA1IIdGhy'
    'ZWFkSWQ=');

@$core.Deprecated('Use markReadDescriptor instead')
const MarkRead$json = {
  '1': 'MarkRead',
  '2': [
    {'1': 'thread_id', '3': 1, '4': 1, '5': 3, '10': 'threadId'},
  ],
};

/// Descriptor for `MarkRead`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markReadDescriptor = $convert
    .base64Decode('CghNYXJrUmVhZBIbCgl0aHJlYWRfaWQYASABKANSCHRocmVhZElk');

@$core.Deprecated('Use markReadResultDescriptor instead')
const MarkReadResult$json = {
  '1': 'MarkReadResult',
  '2': [
    {'1': 'applied', '3': 1, '4': 1, '5': 8, '10': 'applied'},
  ],
};

/// Descriptor for `MarkReadResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markReadResultDescriptor = $convert
    .base64Decode('Cg5NYXJrUmVhZFJlc3VsdBIYCgdhcHBsaWVkGAEgASgIUgdhcHBsaWVk');

@$core.Deprecated('Use messagesChangedDescriptor instead')
const MessagesChanged$json = {
  '1': 'MessagesChanged',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.ferret.messages.v1.Message',
      '10': 'messages'
    },
    {
      '1': 'conversations',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.ferret.messages.v1.Conversation',
      '10': 'conversations'
    },
  ],
};

/// Descriptor for `MessagesChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messagesChangedDescriptor = $convert.base64Decode(
    'Cg9NZXNzYWdlc0NoYW5nZWQSNwoIbWVzc2FnZXMYASADKAsyGy5mZXJyZXQubWVzc2FnZXMudj'
    'EuTWVzc2FnZVIIbWVzc2FnZXMSRgoNY29udmVyc2F0aW9ucxgCIAMoCzIgLmZlcnJldC5tZXNz'
    'YWdlcy52MS5Db252ZXJzYXRpb25SDWNvbnZlcnNhdGlvbnM=');
