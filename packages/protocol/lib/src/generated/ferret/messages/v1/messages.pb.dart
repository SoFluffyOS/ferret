// This is a generated file - do not edit.
//
// Generated from ferret/messages/v1/messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'messages.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'messages.pbenum.dart';

/// Someone in a conversation.
class Participant extends $pb.GeneratedMessage {
  factory Participant({
    $core.String? address,
    $core.String? name,
    $core.List<$core.int>? avatarJpeg,
  }) {
    final result = Participant._();
    if (address != null) result.address = address;
    if (name != null) result.name = name;
    if (avatarJpeg != null) result.avatarJpeg = avatarJpeg;
    return result;
  }

  Participant._();

  factory Participant.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Participant()..mergeFromBuffer(data, registry);
  factory Participant.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Participant()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Participant',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: Participant.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'address')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'avatarJpeg', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Participant clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Participant copyWith(void Function(Participant) updates) =>
      super.copyWith((message) => updates(message as Participant))
          as Participant;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Participant() / Participant.new instead')
  static Participant create() => Participant._();
  static $pb.GeneratedMessage $_createMessage() => Participant._();
  @$core.override
  Participant createEmptyInstance() => Participant._();
  @$core.pragma('dart2js:noInline')
  static Participant getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Participant>(
          Participant.$_createMessage);
  static Participant? _defaultInstance;

  /// The phone number or email address as the phone stores it.
  @$pb.TagNumber(1)
  $core.String get address => $_getSZ(0);
  @$pb.TagNumber(1)
  set address($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddress() => $_clearField(1);

  /// The contact's name on the phone, or empty when it isn't a contact.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  /// A small JPEG of the contact's photo (at most 96 px), or empty.
  @$pb.TagNumber(3)
  $core.List<$core.int> get avatarJpeg => $_getN(2);
  @$pb.TagNumber(3)
  set avatarJpeg($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatarJpeg() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatarJpeg() => $_clearField(3);
}

/// A conversation (an Android thread).
class Conversation extends $pb.GeneratedMessage {
  factory Conversation({
    $fixnum.Int64? threadId,
    $core.Iterable<Participant>? participants,
    $core.String? snippet,
    $fixnum.Int64? lastDateMs,
    $core.int? unreadCount,
    $core.bool? isGroup,
  }) {
    final result = Conversation._();
    if (threadId != null) result.threadId = threadId;
    if (participants != null) result.participants.addAll(participants);
    if (snippet != null) result.snippet = snippet;
    if (lastDateMs != null) result.lastDateMs = lastDateMs;
    if (unreadCount != null) result.unreadCount = unreadCount;
    if (isGroup != null) result.isGroup = isGroup;
    return result;
  }

  Conversation._();

  factory Conversation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Conversation()..mergeFromBuffer(data, registry);
  factory Conversation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Conversation()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Conversation',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: Conversation.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'threadId')
    ..pPM<Participant>(2, _omitFieldNames ? '' : 'participants',
        subBuilder: Participant.$_createMessage)
    ..aOS(3, _omitFieldNames ? '' : 'snippet')
    ..aInt64(4, _omitFieldNames ? '' : 'lastDateMs')
    ..aI(5, _omitFieldNames ? '' : 'unreadCount',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(6, _omitFieldNames ? '' : 'isGroup')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Conversation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Conversation copyWith(void Function(Conversation) updates) =>
      super.copyWith((message) => updates(message as Conversation))
          as Conversation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Conversation() / Conversation.new instead')
  static Conversation create() => Conversation._();
  static $pb.GeneratedMessage $_createMessage() => Conversation._();
  @$core.override
  Conversation createEmptyInstance() => Conversation._();
  @$core.pragma('dart2js:noInline')
  static Conversation getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Conversation>(
          Conversation.$_createMessage);
  static Conversation? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get threadId => $_getI64(0);
  @$pb.TagNumber(1)
  set threadId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasThreadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearThreadId() => $_clearField(1);

  /// Everyone in it except the phone's owner.
  @$pb.TagNumber(2)
  $pb.PbList<Participant> get participants => $_getList(1);

  /// The last message's text, or empty when it was only an attachment.
  @$pb.TagNumber(3)
  $core.String get snippet => $_getSZ(2);
  @$pb.TagNumber(3)
  set snippet($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSnippet() => $_has(2);
  @$pb.TagNumber(3)
  void clearSnippet() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lastDateMs => $_getI64(3);
  @$pb.TagNumber(4)
  set lastDateMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastDateMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastDateMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get unreadCount => $_getIZ(4);
  @$pb.TagNumber(5)
  set unreadCount($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasUnreadCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearUnreadCount() => $_clearField(5);

  /// More than one other person, as in a group MMS.
  @$pb.TagNumber(6)
  $core.bool get isGroup => $_getBF(5);
  @$pb.TagNumber(6)
  set isGroup($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsGroup() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsGroup() => $_clearField(6);
}

/// A file in an MMS, such as a photo.
class Attachment extends $pb.GeneratedMessage {
  factory Attachment({
    $core.String? partId,
    $core.String? mime,
    $fixnum.Int64? size,
    $core.List<$core.int>? thumbnailJpeg,
    $core.String? name,
  }) {
    final result = Attachment._();
    if (partId != null) result.partId = partId;
    if (mime != null) result.mime = mime;
    if (size != null) result.size = size;
    if (thumbnailJpeg != null) result.thumbnailJpeg = thumbnailJpeg;
    if (name != null) result.name = name;
    return result;
  }

  Attachment._();

  factory Attachment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Attachment()..mergeFromBuffer(data, registry);
  factory Attachment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Attachment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Attachment',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: Attachment.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'partId')
    ..aOS(2, _omitFieldNames ? '' : 'mime')
    ..aInt64(3, _omitFieldNames ? '' : 'size')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'thumbnailJpeg', $pb.PbFieldType.OY)
    ..aOS(5, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Attachment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Attachment copyWith(void Function(Attachment) updates) =>
      super.copyWith((message) => updates(message as Attachment)) as Attachment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Attachment() / Attachment.new instead')
  static Attachment create() => Attachment._();
  static $pb.GeneratedMessage $_createMessage() => Attachment._();
  @$core.override
  Attachment createEmptyInstance() => Attachment._();
  @$core.pragma('dart2js:noInline')
  static Attachment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Attachment>(Attachment.$_createMessage);
  static Attachment? _defaultInstance;

  /// The MMS part's id on the phone; send it back in `FetchAttachment`.
  @$pb.TagNumber(1)
  $core.String get partId => $_getSZ(0);
  @$pb.TagNumber(1)
  set partId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPartId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPartId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get mime => $_getSZ(1);
  @$pb.TagNumber(2)
  set mime($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMime() => $_has(1);
  @$pb.TagNumber(2)
  void clearMime() => $_clearField(2);

  /// Bytes, or 0 when unknown.
  @$pb.TagNumber(3)
  $fixnum.Int64 get size => $_getI64(2);
  @$pb.TagNumber(3)
  set size($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearSize() => $_clearField(3);

  /// A small JPEG preview (at most 320 px) for images, or empty.
  @$pb.TagNumber(4)
  $core.List<$core.int> get thumbnailJpeg => $_getN(3);
  @$pb.TagNumber(4)
  set thumbnailJpeg($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasThumbnailJpeg() => $_has(3);
  @$pb.TagNumber(4)
  void clearThumbnailJpeg() => $_clearField(4);

  /// The file name the sender gave, or empty.
  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => $_clearField(5);
}

class Message extends $pb.GeneratedMessage {
  factory Message({
    $core.String? id,
    $fixnum.Int64? threadId,
    $core.String? senderAddress,
    $core.String? body,
    $fixnum.Int64? dateMs,
    MessageKind? kind,
    $core.Iterable<Attachment>? attachments,
    $core.bool? read,
  }) {
    final result = Message._();
    if (id != null) result.id = id;
    if (threadId != null) result.threadId = threadId;
    if (senderAddress != null) result.senderAddress = senderAddress;
    if (body != null) result.body = body;
    if (dateMs != null) result.dateMs = dateMs;
    if (kind != null) result.kind = kind;
    if (attachments != null) result.attachments.addAll(attachments);
    if (read != null) result.read = read;
    return result;
  }

  Message._();

  factory Message.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Message()..mergeFromBuffer(data, registry);
  factory Message.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Message()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Message',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: Message.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aInt64(2, _omitFieldNames ? '' : 'threadId')
    ..aOS(3, _omitFieldNames ? '' : 'senderAddress')
    ..aOS(4, _omitFieldNames ? '' : 'body')
    ..aInt64(5, _omitFieldNames ? '' : 'dateMs')
    ..aE<MessageKind>(6, _omitFieldNames ? '' : 'kind',
        enumValues: MessageKind.values)
    ..pPM<Attachment>(7, _omitFieldNames ? '' : 'attachments',
        subBuilder: Attachment.$_createMessage)
    ..aOB(8, _omitFieldNames ? '' : 'read')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Message copyWith(void Function(Message) updates) =>
      super.copyWith((message) => updates(message as Message)) as Message;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Message() / Message.new instead')
  static Message create() => Message._();
  static $pb.GeneratedMessage $_createMessage() => Message._();
  @$core.override
  Message createEmptyInstance() => Message._();
  @$core.pragma('dart2js:noInline')
  static Message getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Message>(Message.$_createMessage);
  static Message? _defaultInstance;

  /// Unique on the phone across SMS and MMS, such as "sms:12" or "mms:7".
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get threadId => $_getI64(1);
  @$pb.TagNumber(2)
  set threadId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasThreadId() => $_has(1);
  @$pb.TagNumber(2)
  void clearThreadId() => $_clearField(2);

  /// Who sent it, for received messages; empty for messages sent from the
  /// phone.
  @$pb.TagNumber(3)
  $core.String get senderAddress => $_getSZ(2);
  @$pb.TagNumber(3)
  set senderAddress($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSenderAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearSenderAddress() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get body => $_getSZ(3);
  @$pb.TagNumber(4)
  set body($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBody() => $_has(3);
  @$pb.TagNumber(4)
  void clearBody() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get dateMs => $_getI64(4);
  @$pb.TagNumber(5)
  set dateMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDateMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearDateMs() => $_clearField(5);

  @$pb.TagNumber(6)
  MessageKind get kind => $_getN(5);
  @$pb.TagNumber(6)
  set kind(MessageKind value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasKind() => $_has(5);
  @$pb.TagNumber(6)
  void clearKind() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<Attachment> get attachments => $_getList(6);

  @$pb.TagNumber(8)
  $core.bool get read => $_getBF(7);
  @$pb.TagNumber(8)
  set read($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRead() => $_has(7);
  @$pb.TagNumber(8)
  void clearRead() => $_clearField(8);
}

/// What the source can do right now. Answers a `StatusRequest`, and is pushed
/// without a request whenever it changes.
class MessagesStatus extends $pb.GeneratedMessage {
  factory MessagesStatus({
    $core.bool? enabled,
    $core.bool? smsAccess,
    $core.bool? sendAccess,
    $core.bool? contactsAccess,
  }) {
    final result = MessagesStatus._();
    if (enabled != null) result.enabled = enabled;
    if (smsAccess != null) result.smsAccess = smsAccess;
    if (sendAccess != null) result.sendAccess = sendAccess;
    if (contactsAccess != null) result.contactsAccess = contactsAccess;
    return result;
  }

  MessagesStatus._();

  factory MessagesStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessagesStatus()..mergeFromBuffer(data, registry);
  factory MessagesStatus.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessagesStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessagesStatus',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: MessagesStatus.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'smsAccess')
    ..aOB(3, _omitFieldNames ? '' : 'sendAccess')
    ..aOB(4, _omitFieldNames ? '' : 'contactsAccess')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagesStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagesStatus copyWith(void Function(MessagesStatus) updates) =>
      super.copyWith((message) => updates(message as MessagesStatus))
          as MessagesStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessagesStatus() / MessagesStatus.new instead')
  static MessagesStatus create() => MessagesStatus._();
  static $pb.GeneratedMessage $_createMessage() => MessagesStatus._();
  @$core.override
  MessagesStatus createEmptyInstance() => MessagesStatus._();
  @$core.pragma('dart2js:noInline')
  static MessagesStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessagesStatus>(
          MessagesStatus.$_createMessage);
  static MessagesStatus? _defaultInstance;

  /// The person turned Messages on on the phone.
  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  /// The phone lets Ferret read SMS.
  @$pb.TagNumber(2)
  $core.bool get smsAccess => $_getBF(1);
  @$pb.TagNumber(2)
  set smsAccess($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSmsAccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearSmsAccess() => $_clearField(2);

  /// The phone lets Ferret send SMS.
  @$pb.TagNumber(3)
  $core.bool get sendAccess => $_getBF(2);
  @$pb.TagNumber(3)
  set sendAccess($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSendAccess() => $_has(2);
  @$pb.TagNumber(3)
  void clearSendAccess() => $_clearField(3);

  /// The phone lets Ferret read contacts for names and photos.
  @$pb.TagNumber(4)
  $core.bool get contactsAccess => $_getBF(3);
  @$pb.TagNumber(4)
  set contactsAccess($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasContactsAccess() => $_has(3);
  @$pb.TagNumber(4)
  void clearContactsAccess() => $_clearField(4);
}

/// Expects a `MessagesStatus` reply.
class StatusRequest extends $pb.GeneratedMessage {
  factory StatusRequest() => StatusRequest._();

  StatusRequest._();

  factory StatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatusRequest()..mergeFromBuffer(data, registry);
  factory StatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StatusRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: StatusRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatusRequest copyWith(void Function(StatusRequest) updates) =>
      super.copyWith((message) => updates(message as StatusRequest))
          as StatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatusRequest() / StatusRequest.new instead')
  static StatusRequest create() => StatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => StatusRequest._();
  @$core.override
  StatusRequest createEmptyInstance() => StatusRequest._();
  @$core.pragma('dart2js:noInline')
  static StatusRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusRequest>(
          StatusRequest.$_createMessage);
  static StatusRequest? _defaultInstance;
}

/// Asks for conversations, most recent first. Expects a `ConversationPage`.
class ListConversations extends $pb.GeneratedMessage {
  factory ListConversations({
    $fixnum.Int64? beforeDateMs,
    $core.int? limit,
  }) {
    final result = ListConversations._();
    if (beforeDateMs != null) result.beforeDateMs = beforeDateMs;
    if (limit != null) result.limit = limit;
    return result;
  }

  ListConversations._();

  factory ListConversations.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversations()..mergeFromBuffer(data, registry);
  factory ListConversations.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConversations()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListConversations',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: ListConversations.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'beforeDateMs')
    ..aI(2, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversations clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConversations copyWith(void Function(ListConversations) updates) =>
      super.copyWith((message) => updates(message as ListConversations))
          as ListConversations;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListConversations() / ListConversations.new instead')
  static ListConversations create() => ListConversations._();
  static $pb.GeneratedMessage $_createMessage() => ListConversations._();
  @$core.override
  ListConversations createEmptyInstance() => ListConversations._();
  @$core.pragma('dart2js:noInline')
  static ListConversations getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListConversations>(
          ListConversations.$_createMessage);
  static ListConversations? _defaultInstance;

  /// Only conversations whose last message is older than this; 0 for the
  /// newest.
  @$pb.TagNumber(1)
  $fixnum.Int64 get beforeDateMs => $_getI64(0);
  @$pb.TagNumber(1)
  set beforeDateMs($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBeforeDateMs() => $_has(0);
  @$pb.TagNumber(1)
  void clearBeforeDateMs() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);
}

class ConversationPage extends $pb.GeneratedMessage {
  factory ConversationPage({
    $core.Iterable<Conversation>? conversations,
    $core.bool? hasMore,
  }) {
    final result = ConversationPage._();
    if (conversations != null) result.conversations.addAll(conversations);
    if (hasMore != null) result.hasMore = hasMore;
    return result;
  }

  ConversationPage._();

  factory ConversationPage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationPage()..mergeFromBuffer(data, registry);
  factory ConversationPage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConversationPage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ConversationPage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: ConversationPage.$_createMessage)
    ..pPM<Conversation>(1, _omitFieldNames ? '' : 'conversations',
        subBuilder: Conversation.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'hasMore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationPage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConversationPage copyWith(void Function(ConversationPage) updates) =>
      super.copyWith((message) => updates(message as ConversationPage))
          as ConversationPage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConversationPage() / ConversationPage.new instead')
  static ConversationPage create() => ConversationPage._();
  static $pb.GeneratedMessage $_createMessage() => ConversationPage._();
  @$core.override
  ConversationPage createEmptyInstance() => ConversationPage._();
  @$core.pragma('dart2js:noInline')
  static ConversationPage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConversationPage>(
          ConversationPage.$_createMessage);
  static ConversationPage? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Conversation> get conversations => $_getList(0);

  /// There are older conversations.
  @$pb.TagNumber(2)
  $core.bool get hasMore => $_getBF(1);
  @$pb.TagNumber(2)
  set hasMore($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHasMore() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasMore() => $_clearField(2);
}

/// Asks for messages of one conversation, newest first. Expects a
/// `MessagePage`.
class ListMessages extends $pb.GeneratedMessage {
  factory ListMessages({
    $fixnum.Int64? threadId,
    $fixnum.Int64? beforeDateMs,
    $core.Iterable<$core.String>? skipIds,
    $core.int? limit,
  }) {
    final result = ListMessages._();
    if (threadId != null) result.threadId = threadId;
    if (beforeDateMs != null) result.beforeDateMs = beforeDateMs;
    if (skipIds != null) result.skipIds.addAll(skipIds);
    if (limit != null) result.limit = limit;
    return result;
  }

  ListMessages._();

  factory ListMessages.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessages()..mergeFromBuffer(data, registry);
  factory ListMessages.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListMessages()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListMessages',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: ListMessages.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'threadId')
    ..aInt64(2, _omitFieldNames ? '' : 'beforeDateMs')
    ..pPS(3, _omitFieldNames ? '' : 'skipIds')
    ..aI(4, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessages clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListMessages copyWith(void Function(ListMessages) updates) =>
      super.copyWith((message) => updates(message as ListMessages))
          as ListMessages;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListMessages() / ListMessages.new instead')
  static ListMessages create() => ListMessages._();
  static $pb.GeneratedMessage $_createMessage() => ListMessages._();
  @$core.override
  ListMessages createEmptyInstance() => ListMessages._();
  @$core.pragma('dart2js:noInline')
  static ListMessages getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListMessages>(
          ListMessages.$_createMessage);
  static ListMessages? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get threadId => $_getI64(0);
  @$pb.TagNumber(1)
  set threadId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasThreadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearThreadId() => $_clearField(1);

  /// Only messages at or before this date; 0 for the newest.
  @$pb.TagNumber(2)
  $fixnum.Int64 get beforeDateMs => $_getI64(1);
  @$pb.TagNumber(2)
  set beforeDateMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBeforeDateMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeforeDateMs() => $_clearField(2);

  /// Messages at exactly `before_date_ms` the asker already has, so pages
  /// never skip messages that share a date.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get skipIds => $_getList(2);

  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);
}

class MessagePage extends $pb.GeneratedMessage {
  factory MessagePage({
    $fixnum.Int64? threadId,
    $core.Iterable<Message>? messages,
    $core.bool? hasMore,
  }) {
    final result = MessagePage._();
    if (threadId != null) result.threadId = threadId;
    if (messages != null) result.messages.addAll(messages);
    if (hasMore != null) result.hasMore = hasMore;
    return result;
  }

  MessagePage._();

  factory MessagePage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessagePage()..mergeFromBuffer(data, registry);
  factory MessagePage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessagePage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessagePage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: MessagePage.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'threadId')
    ..pPM<Message>(2, _omitFieldNames ? '' : 'messages',
        subBuilder: Message.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'hasMore')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagePage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagePage copyWith(void Function(MessagePage) updates) =>
      super.copyWith((message) => updates(message as MessagePage))
          as MessagePage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessagePage() / MessagePage.new instead')
  static MessagePage create() => MessagePage._();
  static $pb.GeneratedMessage $_createMessage() => MessagePage._();
  @$core.override
  MessagePage createEmptyInstance() => MessagePage._();
  @$core.pragma('dart2js:noInline')
  static MessagePage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessagePage>(
          MessagePage.$_createMessage);
  static MessagePage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get threadId => $_getI64(0);
  @$pb.TagNumber(1)
  set threadId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasThreadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearThreadId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Message> get messages => $_getList(1);

  /// There are older messages.
  @$pb.TagNumber(3)
  $core.bool get hasMore => $_getBF(2);
  @$pb.TagNumber(3)
  set hasMore($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasMore() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasMore() => $_clearField(3);
}

/// Asks for one attachment in full. Expects an `AttachmentData`.
class FetchAttachment extends $pb.GeneratedMessage {
  factory FetchAttachment({
    $core.String? messageId,
    $core.String? partId,
  }) {
    final result = FetchAttachment._();
    if (messageId != null) result.messageId = messageId;
    if (partId != null) result.partId = partId;
    return result;
  }

  FetchAttachment._();

  factory FetchAttachment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchAttachment()..mergeFromBuffer(data, registry);
  factory FetchAttachment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchAttachment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'FetchAttachment',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: FetchAttachment.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aOS(2, _omitFieldNames ? '' : 'partId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchAttachment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchAttachment copyWith(void Function(FetchAttachment) updates) =>
      super.copyWith((message) => updates(message as FetchAttachment))
          as FetchAttachment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FetchAttachment() / FetchAttachment.new instead')
  static FetchAttachment create() => FetchAttachment._();
  static $pb.GeneratedMessage $_createMessage() => FetchAttachment._();
  @$core.override
  FetchAttachment createEmptyInstance() => FetchAttachment._();
  @$core.pragma('dart2js:noInline')
  static FetchAttachment getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FetchAttachment>(
          FetchAttachment.$_createMessage);
  static FetchAttachment? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get partId => $_getSZ(1);
  @$pb.TagNumber(2)
  set partId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPartId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPartId() => $_clearField(2);
}

class AttachmentData extends $pb.GeneratedMessage {
  factory AttachmentData({
    $core.String? mime,
    $core.List<$core.int>? data,
  }) {
    final result = AttachmentData._();
    if (mime != null) result.mime = mime;
    if (data != null) result.data = data;
    return result;
  }

  AttachmentData._();

  factory AttachmentData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachmentData()..mergeFromBuffer(data, registry);
  factory AttachmentData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttachmentData()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AttachmentData',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: AttachmentData.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'mime')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttachmentData copyWith(void Function(AttachmentData) updates) =>
      super.copyWith((message) => updates(message as AttachmentData))
          as AttachmentData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AttachmentData() / AttachmentData.new instead')
  static AttachmentData create() => AttachmentData._();
  static $pb.GeneratedMessage $_createMessage() => AttachmentData._();
  @$core.override
  AttachmentData createEmptyInstance() => AttachmentData._();
  @$core.pragma('dart2js:noInline')
  static AttachmentData getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AttachmentData>(
          AttachmentData.$_createMessage);
  static AttachmentData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mime => $_getSZ(0);
  @$pb.TagNumber(1)
  set mime($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMime() => $_has(0);
  @$pb.TagNumber(1)
  void clearMime() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => $_clearField(2);
}

/// Sends an SMS. Expects a `SendResult`.
class SendText extends $pb.GeneratedMessage {
  factory SendText({
    $fixnum.Int64? threadId,
    $core.Iterable<$core.String>? addresses,
    $core.String? text,
  }) {
    final result = SendText._();
    if (threadId != null) result.threadId = threadId;
    if (addresses != null) result.addresses.addAll(addresses);
    if (text != null) result.text = text;
    return result;
  }

  SendText._();

  factory SendText.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendText()..mergeFromBuffer(data, registry);
  factory SendText.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendText()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendText',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: SendText.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'threadId')
    ..pPS(2, _omitFieldNames ? '' : 'addresses')
    ..aOS(3, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendText clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendText copyWith(void Function(SendText) updates) =>
      super.copyWith((message) => updates(message as SendText)) as SendText;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendText() / SendText.new instead')
  static SendText create() => SendText._();
  static $pb.GeneratedMessage $_createMessage() => SendText._();
  @$core.override
  SendText createEmptyInstance() => SendText._();
  @$core.pragma('dart2js:noInline')
  static SendText getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendText>(SendText.$_createMessage);
  static SendText? _defaultInstance;

  /// The conversation to answer, or 0 to start one with `addresses`.
  @$pb.TagNumber(1)
  $fixnum.Int64 get threadId => $_getI64(0);
  @$pb.TagNumber(1)
  set threadId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasThreadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearThreadId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get addresses => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get text => $_getSZ(2);
  @$pb.TagNumber(3)
  set text($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasText() => $_has(2);
  @$pb.TagNumber(3)
  void clearText() => $_clearField(3);
}

class SendResult extends $pb.GeneratedMessage {
  factory SendResult({
    $core.bool? ok,
    SendFailure? failure,
    $fixnum.Int64? threadId,
  }) {
    final result = SendResult._();
    if (ok != null) result.ok = ok;
    if (failure != null) result.failure = failure;
    if (threadId != null) result.threadId = threadId;
    return result;
  }

  SendResult._();

  factory SendResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendResult()..mergeFromBuffer(data, registry);
  factory SendResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SendResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SendResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: SendResult.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'ok')
    ..aE<SendFailure>(2, _omitFieldNames ? '' : 'failure',
        enumValues: SendFailure.values)
    ..aInt64(3, _omitFieldNames ? '' : 'threadId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SendResult copyWith(void Function(SendResult) updates) =>
      super.copyWith((message) => updates(message as SendResult)) as SendResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SendResult() / SendResult.new instead')
  static SendResult create() => SendResult._();
  static $pb.GeneratedMessage $_createMessage() => SendResult._();
  @$core.override
  SendResult createEmptyInstance() => SendResult._();
  @$core.pragma('dart2js:noInline')
  static SendResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SendResult>(SendResult.$_createMessage);
  static SendResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get ok => $_getBF(0);
  @$pb.TagNumber(1)
  set ok($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);

  @$pb.TagNumber(2)
  SendFailure get failure => $_getN(1);
  @$pb.TagNumber(2)
  set failure(SendFailure value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasFailure() => $_has(1);
  @$pb.TagNumber(2)
  void clearFailure() => $_clearField(2);

  /// The conversation the message went to, when known.
  @$pb.TagNumber(3)
  $fixnum.Int64 get threadId => $_getI64(2);
  @$pb.TagNumber(3)
  set threadId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasThreadId() => $_has(2);
  @$pb.TagNumber(3)
  void clearThreadId() => $_clearField(3);
}

/// Marks a conversation as read. Expects a `MarkReadResult`.
class MarkRead extends $pb.GeneratedMessage {
  factory MarkRead({
    $fixnum.Int64? threadId,
  }) {
    final result = MarkRead._();
    if (threadId != null) result.threadId = threadId;
    return result;
  }

  MarkRead._();

  factory MarkRead.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRead()..mergeFromBuffer(data, registry);
  factory MarkRead.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkRead()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkRead',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: MarkRead.$_createMessage)
    ..aInt64(1, _omitFieldNames ? '' : 'threadId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRead clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkRead copyWith(void Function(MarkRead) updates) =>
      super.copyWith((message) => updates(message as MarkRead)) as MarkRead;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarkRead() / MarkRead.new instead')
  static MarkRead create() => MarkRead._();
  static $pb.GeneratedMessage $_createMessage() => MarkRead._();
  @$core.override
  MarkRead createEmptyInstance() => MarkRead._();
  @$core.pragma('dart2js:noInline')
  static MarkRead getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MarkRead>(MarkRead.$_createMessage);
  static MarkRead? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get threadId => $_getI64(0);
  @$pb.TagNumber(1)
  set threadId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasThreadId() => $_has(0);
  @$pb.TagNumber(1)
  void clearThreadId() => $_clearField(1);
}

class MarkReadResult extends $pb.GeneratedMessage {
  factory MarkReadResult({
    $core.bool? applied,
  }) {
    final result = MarkReadResult._();
    if (applied != null) result.applied = applied;
    return result;
  }

  MarkReadResult._();

  factory MarkReadResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkReadResult()..mergeFromBuffer(data, registry);
  factory MarkReadResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkReadResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkReadResult',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: MarkReadResult.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'applied')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkReadResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkReadResult copyWith(void Function(MarkReadResult) updates) =>
      super.copyWith((message) => updates(message as MarkReadResult))
          as MarkReadResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarkReadResult() / MarkReadResult.new instead')
  static MarkReadResult create() => MarkReadResult._();
  static $pb.GeneratedMessage $_createMessage() => MarkReadResult._();
  @$core.override
  MarkReadResult createEmptyInstance() => MarkReadResult._();
  @$core.pragma('dart2js:noInline')
  static MarkReadResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MarkReadResult>(
          MarkReadResult.$_createMessage);
  static MarkReadResult? _defaultInstance;

  /// The phone changed it. Android lets only the default messaging app mark
  /// SMS as read, so this is usually false; computers then keep it read
  /// themselves.
  @$pb.TagNumber(1)
  $core.bool get applied => $_getBF(0);
  @$pb.TagNumber(1)
  set applied($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasApplied() => $_has(0);
  @$pb.TagNumber(1)
  void clearApplied() => $_clearField(1);
}

/// New or changed messages and their conversations, pushed by the source
/// without a reply. Only for changes seen while the session is open.
class MessagesChanged extends $pb.GeneratedMessage {
  factory MessagesChanged({
    $core.Iterable<Message>? messages,
    $core.Iterable<Conversation>? conversations,
  }) {
    final result = MessagesChanged._();
    if (messages != null) result.messages.addAll(messages);
    if (conversations != null) result.conversations.addAll(conversations);
    return result;
  }

  MessagesChanged._();

  factory MessagesChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessagesChanged()..mergeFromBuffer(data, registry);
  factory MessagesChanged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessagesChanged()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessagesChanged',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'ferret.messages.v1'),
      createEmptyInstance: MessagesChanged.$_createMessage)
    ..pPM<Message>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: Message.$_createMessage)
    ..pPM<Conversation>(2, _omitFieldNames ? '' : 'conversations',
        subBuilder: Conversation.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagesChanged clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessagesChanged copyWith(void Function(MessagesChanged) updates) =>
      super.copyWith((message) => updates(message as MessagesChanged))
          as MessagesChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessagesChanged() / MessagesChanged.new instead')
  static MessagesChanged create() => MessagesChanged._();
  static $pb.GeneratedMessage $_createMessage() => MessagesChanged._();
  @$core.override
  MessagesChanged createEmptyInstance() => MessagesChanged._();
  @$core.pragma('dart2js:noInline')
  static MessagesChanged getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessagesChanged>(
          MessagesChanged.$_createMessage);
  static MessagesChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Message> get messages => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<Conversation> get conversations => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
