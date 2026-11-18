# Protocol reference

Generated from `proto/` by `scripts/docs.sh reference`. Do not edit by hand.

Every message travels inside an `Envelope` (see `ferret.v1`), whose `feature` field names the feature and whose `type` field is the full message name below.

## `ferret.calls.v1`

### enum `CallDirection`

Who started a call.

| Value | Number | Meaning |
|---|---|---|
| `CALL_DIRECTION_UNSPECIFIED` | 0 |  |
| `CALL_DIRECTION_INCOMING` | 1 | Someone is calling the phone. |
| `CALL_DIRECTION_OUTGOING` | 2 | The phone is calling someone. |

### enum `CallState`

Where a call is in its life.

| Value | Number | Meaning |
|---|---|---|
| `CALL_STATE_UNSPECIFIED` | 0 |  |
| `CALL_STATE_RINGING` | 1 | An incoming call nobody answered yet. |
| `CALL_STATE_DIALING` | 2 | An outgoing call. Phones that can't tell when the other side picks up stay in this state until the call ends. |
| `CALL_STATE_ACTIVE` | 3 |  |
| `CALL_STATE_HELD` | 4 |  |
| `CALL_STATE_ENDED` | 5 | The call is over. The last update for its id. |

### enum `CallOutcome`

How a call that rang ended, when the phone knows.

| Value | Number | Meaning |
|---|---|---|
| `CALL_OUTCOME_UNSPECIFIED` | 0 |  |
| `CALL_OUTCOME_ANSWERED` | 1 |  |
| `CALL_OUTCOME_MISSED` | 2 | It rang out, or the caller gave up. |
| `CALL_OUTCOME_DECLINED` | 3 | Someone declined it through Ferret. |

### message `Call`

One call on a phone.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | Random id chosen by the phone, the same in every update for this call. |
| `number` | `string` | 2 | The other side's number as the phone reports it. Empty when it is hidden or the phone may not read it. |
| `contact_name` | `string` | 3 | The contact's name, empty when the number is not in the contacts. |
| `photo_jpeg` | `bytes` | 4 | The contact's photo as a small JPEG, at most 96 pixels a side. |
| `direction` | `CallDirection` | 5 |  |
| `state` | `CallState` | 6 |  |
| `started_at_ms` | `int64` | 7 | When the call started ringing or dialing, in the phone's clock. |
| `connected_at_ms` | `int64` | 8 | When the call was picked up, in the phone's clock. Zero until then. |
| `outcome` | `CallOutcome` | 9 | Set with CALL_STATE_ENDED. |

### message `CallUpdate`

A call changed. Sent by the phone without expecting a reply, for every change, and once for each ongoing call when a session opens. Calls that already ended are never replayed.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `call` | `Call` | 1 |  |
| `sent_at_ms` | `int64` | 2 | The phone's clock when it sent this, so receivers can show a call timer that does not depend on both clocks agreeing. |

### enum `CallAction`

What a computer asks the phone to do with a call.

| Value | Number | Meaning |
|---|---|---|
| `CALL_ACTION_UNSPECIFIED` | 0 |  |
| `CALL_ACTION_ANSWER` | 1 | Pick up the ringing call. Audio stays on the phone. |
| `CALL_ACTION_END` | 2 | Decline the ringing call, or hang up the ongoing one. |
| `CALL_ACTION_SILENCE` | 3 | Stop the ringtone without declining. |
| `CALL_ACTION_DIAL` | 4 | Call `number`. |

### message `CallCommand`

Request. The phone replies with CallCommandResult.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `action` | `CallAction` | 1 |  |
| `call_id` | `string` | 2 | The call the command is for. The phone refuses a command for a call that is gone. Unused for CALL_ACTION_DIAL. |
| `number` | `string` | 3 | The number to call, for CALL_ACTION_DIAL. |

### enum `CallCommandStatus`

| Value | Number | Meaning |
|---|---|---|
| `CALL_COMMAND_STATUS_UNSPECIFIED` | 0 |  |
| `CALL_COMMAND_STATUS_OK` | 1 |  |
| `CALL_COMMAND_STATUS_NO_CALL` | 2 | The call is gone, or nothing is ringing. |
| `CALL_COMMAND_STATUS_DISABLED` | 3 | Calls are turned off on the phone. |
| `CALL_COMMAND_STATUS_PERMISSION_MISSING` | 4 | The phone's owner did not give Ferret the permission this needs. |
| `CALL_COMMAND_STATUS_UNSUPPORTED` | 5 | This phone's system version can't do it. |
| `CALL_COMMAND_STATUS_INVALID_NUMBER` | 6 | The number is empty or has characters a phone can't dial. |
| `CALL_COMMAND_STATUS_FAILED` | 7 |  |

### message `CallCommandResult`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `status` | `CallCommandStatus` | 1 |  |

### message `GetCallsStatus`

Request. The phone replies with CallsStatus.


### message `GetCallsStatus.CallsStatus`

What the phone can do right now. Also sent on its own when it changes.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `enabled` | `bool` | 1 | The phone's owner turned calls on. |
| `can_see_calls` | `bool` | 2 | The phone may watch its call state. |
| `can_see_numbers` | `bool` | 3 | The phone may read who is calling. |
| `can_answer` | `bool` | 4 | The phone may answer and end calls. |
| `can_dial` | `bool` | 5 | The phone may place calls. |
| `can_read_log` | `bool` | 6 | The phone may read its call history. |
| `can_read_contacts` | `bool` | 7 | The phone may look numbers up in its contacts. |

### enum `GetCallsStatus.CallLogType`

What a past call was.

| Value | Number | Meaning |
|---|---|---|
| `CALL_LOG_TYPE_UNSPECIFIED` | 0 |  |
| `CALL_LOG_TYPE_INCOMING` | 1 |  |
| `CALL_LOG_TYPE_OUTGOING` | 2 |  |
| `CALL_LOG_TYPE_MISSED` | 3 |  |
| `CALL_LOG_TYPE_REJECTED` | 4 | The phone's owner declined it. |

### message `GetCallsStatus.CallLogEntry`

One past call.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | The phone's own id for the entry. |
| `number` | `string` | 2 |  |
| `name` | `string` | 3 | The contact's name, empty when unknown. |
| `type` | `CallLogType` | 4 |  |
| `date_ms` | `int64` | 5 | When the call happened, in the phone's clock. |
| `duration_s` | `int64` | 6 | How long the call lasted, zero when it was not picked up. |

### message `GetCallsStatus.GetCallLog`

Request. The phone replies with CallLog.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `limit` | `uint32` | 1 | The most entries to send back, newest first. Zero means 50; the phone never sends more than 200. |

### message `GetCallsStatus.CallLog`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `entries` | `repeated CallLogEntry` | 1 |  |
| `permission_missing` | `bool` | 2 | The phone may not read its call history, so `entries` is empty. |
| `disabled` | `bool` | 3 | Calls are turned off on the phone, so `entries` is empty. |

## `ferret.clipboard.v1`

### enum `ClipKind`

What a clip holds, so receivers can preview it without parsing.

| Value | Number | Meaning |
|---|---|---|
| `CLIP_KIND_UNSPECIFIED` | 0 |  |
| `CLIP_KIND_TEXT` | 1 |  |
| `CLIP_KIND_IMAGE` | 2 |  |
| `CLIP_KIND_URL` | 3 | Text that is a single http or https link. |

### message `ClipItem`

One thing someone copied.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | Random id chosen by the source device, used to drop duplicates. |
| `kind` | `ClipKind` | 2 |  |
| `text` | `string` | 3 | Set for CLIP_KIND_TEXT and CLIP_KIND_URL. |
| `image` | `bytes` | 4 | Encoded image bytes, set for CLIP_KIND_IMAGE. |
| `image_mime` | `string` | 5 | Media type of `image`, such as "image/png". |
| `created_at_ms` | `int64` | 6 | When it was copied, in the source device's clock. |
| `source_device_id` | `string` | 7 | Device id of the device it was copied on. |
| `sensitive` | `bool` | 8 | The source app marked it as private, such as a password manager. Receivers keep it out of history and clipboard managers. |
| `content_hash` | `bytes` | 9 | SHA-256 of the content (kind, text or image bytes), so devices can drop echoes of what they wrote themselves. |

### message `ClipPush`

Puts `item` on the receiver's clipboard. Sent without expecting a reply.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `item` | `ClipItem` | 1 |  |
| `expires_in_ms` | `int64` | 2 | How long the item stays useful after `created_at_ms`. Receivers drop sensitive items from memory once it passes. |

## `ferret.drop.v1`

### message `FileInfo`

One file in a transfer offer.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `name` | `string` | 1 | Base name only; the receiver never trusts it as a path. |
| `size` | `uint64` | 2 |  |
| `mime` | `string` | 3 |  |
| `sha256` | `bytes` | 4 | SHA-256 of the whole file when the sender knows it up front. The authoritative hash always arrives in FileComplete. |

### message `TransferOffer`

Asks to send files or text (a request, answered with TransferAnswer). Sending the same transfer_id again after a dropped session resumes it.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `transfer_id` | `string` | 1 |  |
| `files` | `repeated FileInfo` | 2 |  |
| `text` | `string` | 3 | Text to drop instead of, or along with, files. |
| `chunk_size` | `uint32` | 4 | Size of each chunk the sender will send. |

### message `TransferAnswer`

The answer to a TransferOffer.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `transfer_id` | `string` | 1 |  |
| `accepted` | `bool` | 2 |  |
| `reason` | `DeclineReason` | 3 |  |
| `file_index` | `uint32` | 4 | Where to start sending: the first file that isn't complete yet and the byte offset in it. Both are 0 for a new transfer. |
| `offset` | `uint64` | 5 |  |

### enum `DeclineReason`

| Value | Number | Meaning |
|---|---|---|
| `DECLINE_REASON_UNSPECIFIED` | 0 |  |
| `DECLINE_REASON_DECLINED` | 1 | Someone on the receiving device said no. |
| `DECLINE_REASON_TIMEOUT` | 2 | Nobody answered in time. |
| `DECLINE_REASON_STORAGE` | 3 | The receiver can't write to its receive folder. |
| `DECLINE_REASON_UNKNOWN_TRANSFER` | 4 | The receiver doesn't know this transfer any more and can't resume it. |
| `DECLINE_REASON_INVALID` | 5 | The offer is malformed, such as a file without a name. |

### message `Chunk`

A piece of one file. Every few chunks are sent as a request, answered with ChunkReceived once the receiver wrote them, which bounds the data in flight.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `transfer_id` | `string` | 1 |  |
| `file_index` | `uint32` | 2 |  |
| `offset` | `uint64` | 3 |  |
| `data` | `bytes` | 4 |  |

### message `ChunkReceived`

Confirms the receiver wrote everything up to offset of file_index.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `transfer_id` | `string` | 1 |  |
| `file_index` | `uint32` | 2 |  |
| `offset` | `uint64` | 3 |  |

### message `FileComplete`

The last chunk of a file was sent (a request, answered with FileVerified).

| Field | Type | Number | Meaning |
|---|---|---|---|
| `transfer_id` | `string` | 1 |  |
| `file_index` | `uint32` | 2 |  |
| `sha256` | `bytes` | 3 |  |

### message `FileVerified`

Whether the receiver's copy matched the hash and was saved.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `transfer_id` | `string` | 1 |  |
| `file_index` | `uint32` | 2 |  |
| `ok` | `bool` | 3 |  |
| `reason` | `FailureReason` | 4 |  |

### message `TransferComplete`

Every file was sent and verified.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `transfer_id` | `string` | 1 |  |

### message `Cancel`

Either side stops a transfer.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `transfer_id` | `string` | 1 |  |
| `reason` | `FailureReason` | 2 |  |

### enum `FailureReason`

| Value | Number | Meaning |
|---|---|---|
| `FAILURE_REASON_UNSPECIFIED` | 0 |  |
| `FAILURE_REASON_CANCELLED` | 1 | Someone cancelled it. |
| `FAILURE_REASON_CHECKSUM` | 2 | The received data didn't match the sender's SHA-256. |
| `FAILURE_REASON_STORAGE` | 3 | Reading or writing a file failed, such as a full disk. |
| `FAILURE_REASON_SOURCE_CHANGED` | 4 | The sender's file changed or disappeared during the transfer. |
| `FAILURE_REASON_PROTOCOL` | 5 | A chunk didn't match what the receiver expected. |
| `FAILURE_REASON_UNKNOWN_TRANSFER` | 6 | The sender no longer has this transfer, so it can't be resumed. |

### message `ResumeRequest`

Sent by a receiver after a dropped session comes back, to continue an interrupted transfer where it stopped.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `transfer_id` | `string` | 1 |  |
| `file_index` | `uint32` | 2 |  |
| `offset` | `uint64` | 3 |  |

## `ferret.find.v1`

### message `RingRequest`

Asks the receiver to ring so someone can find it. Expects a `RingStatus` reply. Asking a device that already rings restarts its countdown.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `duration_seconds` | `uint32` | 1 | How long to ring before stopping on its own. 0 means the receiver's default; receivers cap long values. |
| `override_silent` | `bool` | 2 | Ring even when the receiver is on silent or Do Not Disturb, if its owner allowed that on the receiver. |

### message `StopRingRequest`

Asks the receiver to stop ringing. Expects a `RingStatus` reply.


### enum `StopRingRequest.RingState`

Whether a device rings.

| Value | Number | Meaning |
|---|---|---|
| `RING_STATE_UNSPECIFIED` | 0 |  |
| `RING_STATE_RINGING` | 1 |  |
| `RING_STATE_STOPPED` | 2 |  |

### enum `StopRingRequest.StopReason`

Why a ring stopped.

| Value | Number | Meaning |
|---|---|---|
| `STOP_REASON_UNSPECIFIED` | 0 |  |
| `STOP_REASON_FOUND` | 1 | Someone tapped "Found it" or pressed a volume key on the ringing device. |
| `STOP_REASON_TIMEOUT` | 2 | The ring ran for its whole duration. |
| `STOP_REASON_STOPPED_REMOTELY` | 3 | A `StopRingRequest` arrived. |
| `STOP_REASON_FAILED` | 4 | The device could not play a sound at all. |

### message `StopRingRequest.RingStatus`

Where a ring stands. The reply to `RingRequest` and `StopRingRequest`, and sent without expecting a reply to each device that asked for the ring when it stops on the ringing device.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `state` | `RingState` | 1 |  |
| `reason` | `StopReason` | 2 | Set when `state` is `RING_STATE_STOPPED`. |
| `remaining_ms` | `uint32` | 3 | Milliseconds left until the ring stops on its own, while ringing. |
| `muted` | `bool` | 4 | It rings, but without sound, because it is on silent or Do Not Disturb and may not override that. It still vibrates and shows a notice. |

### message `StopRingRequest.GetRingInfo`

Asks what the receiver can do when rung. Expects a `RingInfo` reply.


### message `StopRingRequest.GetRingInfo.RingInfo`

What the receiver can do when rung. The reply to `GetRingInfo`, and sent without expecting a reply when it changes, such as after a permission was granted.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `ringing` | `bool` | 1 | It rings right now. |
| `rings_when_silent` | `bool` | 2 | It rings out loud even on silent or Do Not Disturb. |
| `needs_app_open` | `bool` | 3 | It can only ring while Ferret is open on it, such as on iOS. |
| `needs_permission` | `bool` | 4 | Its owner turned ringing on silent on, but the system permission for it is missing. |

## `ferret.handoff.v1`

### enum `ActivityKind`

What an activity is, which decides how the receiving device opens it.

| Value | Number | Meaning |
|---|---|---|
| `ACTIVITY_KIND_UNSPECIFIED` | 0 |  |
| `ACTIVITY_KIND_WEB` | 1 | A web page: `uri` is http(s). |
| `ACTIVITY_KIND_APP` | 2 | Something inside an app: `deep_link` and `apps`, with `fallback_web_uri` for devices that don't have the app. |
| `ACTIVITY_KIND_GEO` | 3 | A place: `uri` is a geo: URI (RFC 5870). |
| `ACTIVITY_KIND_TEXT` | 4 | Plain text in `text`, such as a note or an address. |

### message `AppIdentifiers`

The app that can continue an activity, per platform. Empty when unknown.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `android_package` | `string` | 1 | Android package name, such as "org.wikipedia". |
| `apple_bundle_id` | `string` | 2 | Bundle id on macOS and iOS, such as "com.apple.Safari". |
| `linux_desktop_id` | `string` | 3 | Desktop entry id on Linux, such as "org.gnome.Maps.desktop". |
| `windows_app_id` | `string` | 4 | AppUserModelID on Windows. |

### message `Activity`

Something the user is doing that another device can continue. Shaped like Android's HandoffActivityData: the activity itself, plus a web URI to fall back to when the app isn't there.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | Unique per activity, chosen by the source device. |
| `kind` | `ActivityKind` | 2 |  |
| `title` | `string` | 3 | Short, human title, such as the page title. |
| `uri` | `string` | 4 | The main URI: http(s), geo: or mailto:. |
| `deep_link` | `string` | 5 | A URI only the app understands, opened in the app named by `apps`. |
| `apps` | `AppIdentifiers` | 6 |  |
| `fallback_web_uri` | `string` | 7 | Opened when no app can take `deep_link`. |
| `text` | `string` | 8 | The text of an ACTIVITY_KIND_TEXT activity. |
| `state` | `bytes` | 9 | Opaque state for apps that opted in, such as scroll position. Ferret never reads it; it is handed to the app as is. |
| `state_type` | `string` | 10 | What `state` holds, such as "application/ld+json" for AssistContent structured data, or a reverse-DNS name chosen by the app. |
| `created_at_ms` | `uint64` | 11 |  |
| `expires_at_ms` | `uint64` | 12 | After this time the activity is stale and is not suggested any more. |
| `source_device_id` | `string` | 13 | Device id of the device the activity comes from. |
| `source_app_name` | `string` | 14 | Name of the app it comes from, such as "Firefox", for display only. |

### message `PublishActivity`

Passive: "this is what I'm doing now". Receivers keep it as a quiet suggestion that expires and is replaced by the next one from the same device. Sent without expecting a reply.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `activity` | `Activity` | 1 |  |

### message `ContinueActivity`

Explicit: "continue this on your side now". Sent as a request; the receiver answers with ContinueResult.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `activity` | `Activity` | 1 |  |

### enum `ContinueOutcome`

What the receiver did with a ContinueActivity.

| Value | Number | Meaning |
|---|---|---|
| `CONTINUE_OUTCOME_UNSPECIFIED` | 0 |  |
| `CONTINUE_OUTCOME_OPENED` | 1 | Opened right away. |
| `CONTINUE_OUTCOME_SUGGESTED` | 2 | Kept as a suggestion with a notice, because the user turned automatic opening off. |
| `CONTINUE_OUTCOME_FAILED` | 3 | Could not open it, such as a URI scheme it doesn't accept. |

### message `ContinueResult`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `outcome` | `ContinueOutcome` | 1 |  |

### message `ClearActivity`

Withdraws suggestions from the sender, such as when the page was closed.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `activity_id` | `string` | 1 | The activity to withdraw, or empty for every one from the sender. |

## `ferret.media.v1`

### message `MediaState`

What a device is playing right now: every media player it can see. Sent when something changes (feature "media"), never on a timer: the receiver extrapolates the position of a playing item itself. An empty list means the device stopped sharing or nothing plays.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `players` | `repeated MediaPlayer` | 1 |  |
| `sent_at_ms` | `uint64` | 2 | The sender's clock when it sent this, so the receiver can map the players' timestamps onto its own clock. |

### message `MediaStateRequest`

Asks a device for its current MediaState (feature "media"). The reply is a MediaState.


### message `MediaStateRequest.MediaPlayer`

One media player, such as Spotify or a browser tab, and what it plays.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `player_id` | `string` | 1 | Stable while the player exists on the sender. |
| `app_id` | `string` | 2 | The app behind the player, such as "com.spotify.music" on Android or "com.spotify.client" on macOS. |
| `app_name` | `string` | 3 |  |
| `title` | `string` | 4 |  |
| `artist` | `string` | 5 |  |
| `album` | `string` | 6 |  |
| `artwork_id` | `string` | 7 | Identifies the artwork, so the image is sent only once per session. |
| `artwork` | `bytes` | 8 | A small JPEG or PNG (at most 64 KiB). Empty when the receiver already got the image for artwork_id in this session. |
| `duration_ms` | `uint64` | 9 | 0 when unknown, such as a live stream. |
| `position_ms` | `uint64` | 10 | The position at position_at_ms. |
| `position_at_ms` | `uint64` | 11 | The sender's clock when position_ms was true. |
| `status` | `MediaPlaybackStatus` | 12 |  |
| `playback_rate` | `float` | 13 | Playback speed while playing; 0 means 1. |
| `content_uri` | `string` | 14 | A link to the item, such as a YouTube URL or a spotify: URI, when the player tells it. |
| `last_active_at_ms` | `uint64` | 15 | The sender's clock when this player last started playing or changed item, to follow the last active player. |
| `actions` | `repeated MediaAction` | 16 |  |
| `volume` | `float` | 17 | Player volume 0 to 1, or -1 when unknown. |

### enum `MediaStateRequest.MediaPlaybackStatus`

| Value | Number | Meaning |
|---|---|---|
| `MEDIA_PLAYBACK_STATUS_UNSPECIFIED` | 0 |  |
| `MEDIA_PLAYBACK_STATUS_STOPPED` | 1 |  |
| `MEDIA_PLAYBACK_STATUS_PAUSED` | 2 |  |
| `MEDIA_PLAYBACK_STATUS_PLAYING` | 3 |  |
| `MEDIA_PLAYBACK_STATUS_BUFFERING` | 4 |  |

### enum `MediaStateRequest.MediaAction`

| Value | Number | Meaning |
|---|---|---|
| `MEDIA_ACTION_UNSPECIFIED` | 0 |  |
| `MEDIA_ACTION_PLAY` | 1 |  |
| `MEDIA_ACTION_PAUSE` | 2 |  |
| `MEDIA_ACTION_TOGGLE` | 3 |  |
| `MEDIA_ACTION_NEXT` | 4 |  |
| `MEDIA_ACTION_PREVIOUS` | 5 |  |
| `MEDIA_ACTION_SEEK` | 6 |  |
| `MEDIA_ACTION_SET_VOLUME` | 7 |  |

### message `MediaStateRequest.MediaCommand`

Asks a device to control one of its players (feature "media"). The reply is a MediaCommandReply.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `player_id` | `string` | 1 |  |
| `action` | `MediaAction` | 2 |  |
| `position_ms` | `uint64` | 3 | For MEDIA_ACTION_SEEK. |
| `volume` | `float` | 4 | For MEDIA_ACTION_SET_VOLUME, 0 to 1. |

### message `MediaStateRequest.MediaCommandReply`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `result` | `MediaCommandResult` | 1 |  |

### enum `MediaStateRequest.MediaCommandResult`

| Value | Number | Meaning |
|---|---|---|
| `MEDIA_COMMAND_RESULT_UNSPECIFIED` | 0 |  |
| `MEDIA_COMMAND_RESULT_OK` | 1 |  |
| `MEDIA_COMMAND_RESULT_UNKNOWN_PLAYER` | 2 | No player with that id, such as one that just closed. |
| `MEDIA_COMMAND_RESULT_NOT_SHARED` | 3 | The user turned off sharing media on that device. |
| `MEDIA_COMMAND_RESULT_UNSUPPORTED` | 4 | The player can't do that action. |
| `MEDIA_COMMAND_RESULT_FAILED` | 5 |  |

### message `MediaStateRequest.MediaContinueRequest`

Asks a device to hand one of its players over (feature "media"): it pauses the player when pause_source is set and replies with a MediaContinueReply holding the item and the position it stopped at.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `player_id` | `string` | 1 |  |
| `pause_source` | `bool` | 2 |  |

### message `MediaStateRequest.MediaContinueReply`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `result` | `MediaCommandResult` | 1 |  |
| `player` | `MediaPlayer` | 2 | The player as it was when it paused, with a fresh position. |
| `paused` | `bool` | 3 | Whether the source paused, so the receiver can resume it if opening the item here fails. |

## `ferret.messages.v1`

### enum `MessageKind`

Where a message sits on the phone.

| Value | Number | Meaning |
|---|---|---|
| `MESSAGE_KIND_UNSPECIFIED` | 0 |  |
| `MESSAGE_KIND_INBOX` | 1 | Received. |
| `MESSAGE_KIND_SENT` | 2 |  |
| `MESSAGE_KIND_OUTBOX` | 3 | Being sent right now. |
| `MESSAGE_KIND_FAILED` | 4 |  |
| `MESSAGE_KIND_QUEUED` | 5 | Waiting to be sent, such as with no signal. |

### message `Participant`

Someone in a conversation.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `address` | `string` | 1 | The phone number or email address as the phone stores it. |
| `name` | `string` | 2 | The contact's name on the phone, or empty when it isn't a contact. |
| `avatar_jpeg` | `bytes` | 3 | A small JPEG of the contact's photo (at most 96 px), or empty. |

### message `Conversation`

A conversation (an Android thread).

| Field | Type | Number | Meaning |
|---|---|---|---|
| `thread_id` | `int64` | 1 |  |
| `participants` | `repeated Participant` | 2 | Everyone in it except the phone's owner. |
| `snippet` | `string` | 3 | The last message's text, or empty when it was only an attachment. |
| `last_date_ms` | `int64` | 4 |  |
| `unread_count` | `uint32` | 5 |  |
| `is_group` | `bool` | 6 | More than one other person, as in a group MMS. |

### message `Attachment`

A file in an MMS, such as a photo.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `part_id` | `string` | 1 | The MMS part's id on the phone; send it back in `FetchAttachment`. |
| `mime` | `string` | 2 |  |
| `size` | `int64` | 3 | Bytes, or 0 when unknown. |
| `thumbnail_jpeg` | `bytes` | 4 | A small JPEG preview (at most 320 px) for images, or empty. |
| `name` | `string` | 5 | The file name the sender gave, or empty. |

### message `Message`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | Unique on the phone across SMS and MMS, such as "sms:12" or "mms:7". |
| `thread_id` | `int64` | 2 |  |
| `sender_address` | `string` | 3 | Who sent it, for received messages; empty for messages sent from the phone. |
| `body` | `string` | 4 |  |
| `date_ms` | `int64` | 5 |  |
| `kind` | `MessageKind` | 6 |  |
| `attachments` | `repeated Attachment` | 7 |  |
| `read` | `bool` | 8 |  |

### message `MessagesStatus`

What the source can do right now. Answers a `StatusRequest`, and is pushed without a request whenever it changes.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `enabled` | `bool` | 1 | The person turned Messages on on the phone. |
| `sms_access` | `bool` | 2 | The phone lets Ferret read SMS. |
| `send_access` | `bool` | 3 | The phone lets Ferret send SMS. |
| `contacts_access` | `bool` | 4 | The phone lets Ferret read contacts for names and photos. |

### message `StatusRequest`

Expects a `MessagesStatus` reply.


### message `StatusRequest.ListConversations`

Asks for conversations, most recent first. Expects a `ConversationPage`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `before_date_ms` | `int64` | 1 | Only conversations whose last message is older than this; 0 for the newest. |
| `limit` | `uint32` | 2 |  |

### message `StatusRequest.ConversationPage`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `conversations` | `repeated Conversation` | 1 |  |
| `has_more` | `bool` | 2 | There are older conversations. |

### message `StatusRequest.ListMessages`

Asks for messages of one conversation, newest first. Expects a `MessagePage`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `thread_id` | `int64` | 1 |  |
| `before_date_ms` | `int64` | 2 | Only messages at or before this date; 0 for the newest. |
| `skip_ids` | `repeated string` | 3 | Messages at exactly `before_date_ms` the asker already has, so pages never skip messages that share a date. |
| `limit` | `uint32` | 4 |  |

### message `StatusRequest.MessagePage`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `thread_id` | `int64` | 1 |  |
| `messages` | `repeated Message` | 2 |  |
| `has_more` | `bool` | 3 | There are older messages. |

### message `StatusRequest.FetchAttachment`

Asks for one attachment in full. Expects an `AttachmentData`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `message_id` | `string` | 1 |  |
| `part_id` | `string` | 2 |  |

### message `StatusRequest.AttachmentData`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `mime` | `string` | 1 |  |
| `data` | `bytes` | 2 |  |

### enum `StatusRequest.SendFailure`

Why a message wasn't sent.

| Value | Number | Meaning |
|---|---|---|
| `SEND_FAILURE_UNSPECIFIED` | 0 |  |
| `SEND_FAILURE_NO_ACCESS` | 1 | Ferret may not send SMS on the phone. |
| `SEND_FAILURE_NO_RECIPIENT` | 2 | No address to send to, or the conversation is gone. |
| `SEND_FAILURE_GROUP` | 3 | Group conversations need MMS, which only the default messaging app sends. |
| `SEND_FAILURE_NO_SERVICE` | 4 | The phone has no signal or the carrier refused it. |
| `SEND_FAILURE_TIMEOUT` | 5 | The radio didn't confirm in time. |
| `SEND_FAILURE_OTHER` | 6 |  |

### message `StatusRequest.SendText`

Sends an SMS. Expects a `SendResult`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `thread_id` | `int64` | 1 | The conversation to answer, or 0 to start one with `addresses`. |
| `addresses` | `repeated string` | 2 |  |
| `text` | `string` | 3 |  |

### message `StatusRequest.SendResult`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `ok` | `bool` | 1 |  |
| `failure` | `SendFailure` | 2 |  |
| `thread_id` | `int64` | 3 | The conversation the message went to, when known. |

### message `StatusRequest.MarkRead`

Marks a conversation as read. Expects a `MarkReadResult`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `thread_id` | `int64` | 1 |  |

### message `StatusRequest.MarkReadResult`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `applied` | `bool` | 1 | The phone changed it. Android lets only the default messaging app mark SMS as read, so this is usually false; computers then keep it read themselves. |

### message `StatusRequest.MessagesChanged`

New or changed messages and their conversations, pushed by the source without a reply. Only for changes seen while the session is open.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `messages` | `repeated Message` | 1 |  |
| `conversations` | `repeated Conversation` | 2 |  |

## `ferret.notifications.v1`

### message `NotificationAction`

A button on a notification, such as "Reply" or "Mark as read".

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | Chosen by the source device; send it back in `InvokeAction`. |
| `title` | `string` | 2 |  |
| `is_reply` | `bool` | 3 | The action takes typed text, such as a message reply. |

### message `NotificationItem`

One notification shown on the source device (a phone).

| Field | Type | Number | Meaning |
|---|---|---|---|
| `key` | `string` | 1 | The source's own key for it. Posting the same key again updates it. |
| `app_package` | `string` | 2 | The app that posted it, such as "org.thoughtcrime.securesms". |
| `app_name` | `string` | 3 |  |
| `title` | `string` | 4 |  |
| `text` | `string` | 5 |  |
| `posted_at_ms` | `int64` | 6 | When the source posted it, in the source device's clock. |
| `app_icon_png` | `bytes` | 7 | A small PNG of the app's icon. Empty when it was already sent for this app during the current session; receivers keep the last one per app. |
| `is_conversation` | `bool` | 8 | A message in a conversation, such as a chat. |
| `actions` | `repeated NotificationAction` | 9 |  |

### message `NotificationPosted`

A new or updated notification. Sent without expecting a reply, only for notifications posted after the session opened.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `notification` | `NotificationItem` | 1 |  |

### message `NotificationRemoved`

The notification with `key` is gone on the source. Sent without expecting a reply.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `key` | `string` | 1 |  |

### message `CatchUp`

Sent by the source right after a session opens, instead of replaying what happened while the receiver was away.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `missed_count` | `uint32` | 1 | Notifications posted while the receiver was away and still showing. |
| `active_keys` | `repeated string` | 2 | Keys of notifications sent earlier that are still showing on the source. Receivers drop the ones not listed. |
| `missed_app_names` | `repeated string` | 3 | Names of the apps the missed notifications came from, without repeats. |

### message `InvokeAction`

Asks the source to run an action of a notification. Expects an `InvokeActionResult` reply.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `key` | `string` | 1 |  |
| `action_id` | `string` | 2 |  |
| `reply_text` | `string` | 3 | The typed text for a reply action. |

### message `InvokeActionResult`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `ok` | `bool` | 1 |  |

### message `DismissNotification`

Dismisses the notification with `key` on the source. Sent without expecting a reply; the source answers with `NotificationRemoved` once it is gone.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `key` | `string` | 1 |  |

### message `MirrorSettings`

How the source mirrors notifications.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `enabled` | `bool` | 1 | The person turned mirroring on. |
| `access_granted` | `bool` | 2 | The platform lets the source read notifications. |
| `skip_while_using` | `bool` | 3 | Mirroring pauses while the source is in use (screen on and unlocked). |
| `allowed_packages` | `repeated string` | 4 | Apps whose notifications are mirrored. |

### message `MirrorSettingsRequest`

Asks the source for its `MirrorSettings`. Expects a `MirrorSettings` reply.


### message `MirrorSettingsRequest.AppEntry`

An app the person can pick in the app list.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `package` | `string` | 1 |  |
| `name` | `string` | 2 |  |
| `icon_png` | `bytes` | 3 | A small PNG of the app's icon. |
| `allowed` | `bool` | 4 |  |
| `is_messaging` | `bool` | 5 | A messaging app, picked by default. |

### message `MirrorSettingsRequest.AppListRequest`

Asks the source for its apps. Expects an `AppListResponse` reply.


### message `MirrorSettingsRequest.AppListRequest.AppListResponse`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `apps` | `repeated AppEntry` | 1 |  |

### message `MirrorSettingsRequest.AppListRequest.AppChoice`

Turns one app on or off.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `package` | `string` | 1 |  |
| `allowed` | `bool` | 2 |  |

### message `MirrorSettingsRequest.AppListRequest.UpdateMirrorSettings`

Changes the source's settings. Expects a `MirrorSettings` reply.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `apps` | `repeated AppChoice` | 1 |  |
| `skip_while_using` | `optional bool` | 2 | Left out to keep the current value. |

## `ferret.v1`

### enum `Platform`

The operating system a device runs.

| Value | Number | Meaning |
|---|---|---|
| `PLATFORM_UNSPECIFIED` | 0 |  |
| `PLATFORM_ANDROID` | 1 |  |
| `PLATFORM_IOS` | 2 |  |
| `PLATFORM_MACOS` | 3 |  |
| `PLATFORM_LINUX` | 4 |  |
| `PLATFORM_WINDOWS` | 5 |  |
| `PLATFORM_BROWSER` | 6 |  |
| `PLATFORM_CLI` | 7 |  |

### enum `FormFactor`

The kind of device, used for icons and for choosing where to suggest things.

| Value | Number | Meaning |
|---|---|---|
| `FORM_FACTOR_UNSPECIFIED` | 0 |  |
| `FORM_FACTOR_PHONE` | 1 |  |
| `FORM_FACTOR_TABLET` | 2 |  |
| `FORM_FACTOR_LAPTOP` | 3 |  |
| `FORM_FACTOR_DESKTOP` | 4 |  |
| `FORM_FACTOR_SERVER` | 5 |  |

### message `DeviceInfo`

What a device says about itself after the secure channel is up.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | Stable id derived from the device's static public key (see spec/identity.md). |
| `name` | `string` | 2 |  |
| `platform` | `Platform` | 3 |  |
| `form_factor` | `FormFactor` | 4 |  |
| `model` | `string` | 5 |  |
| `app_version` | `string` | 6 |  |
| `protocol_version` | `uint32` | 7 | Highest protocol version the device speaks. |

### message `FeatureSupport`

A feature a device offers, with the feature's own version.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | Feature id, such as "handoff" or "clipboard". |
| `version` | `uint32` | 2 |  |
| `flags` | `repeated string` | 3 | Feature-specific flags, such as "send" and "receive". |

### message `Announce`

Sent over UDP multicast so devices on the same network find each other. It carries no secrets: anyone on the network can read it.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `protocol_version` | `uint32` | 1 |  |
| `device_id` | `string` | 2 |  |
| `name` | `string` | 3 |  |
| `platform` | `Platform` | 4 |  |
| `form_factor` | `FormFactor` | 5 |  |
| `port` | `uint32` | 6 |  |
| `reply` | `bool` | 7 | True when this is an answer to someone else's announce, so it is not answered again. |

### message `Envelope`

Every message on a session is an envelope. Features own their payload types, so new features never change this file.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `uint64` | 1 | Sender-chosen, unique per session, never 0. |
| `reply_to` | `uint64` | 2 | The id of the request this answers, or 0. |
| `feature` | `string` | 3 | Feature id, such as "session", "handoff" or "drop". |
| `type` | `string` | 4 | Full protobuf name of the payload, such as "ferret.handoff.v1.Activity". |
| `payload` | `bytes` | 5 |  |
| `error` | `Error` | 6 | Set on a reply that failed instead of a payload. |
| `expects_reply` | `bool` | 7 | The sender waits for a reply (an envelope with reply_to = id). |

### message `Error`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `code` | `ErrorCode` | 1 |  |
| `message` | `string` | 2 |  |

### enum `ErrorCode`

| Value | Number | Meaning |
|---|---|---|
| `ERROR_CODE_UNSPECIFIED` | 0 |  |
| `ERROR_CODE_UNSUPPORTED` | 1 |  |
| `ERROR_CODE_DENIED` | 2 |  |
| `ERROR_CODE_INVALID` | 3 |  |
| `ERROR_CODE_INTERNAL` | 4 |  |
| `ERROR_CODE_TIMEOUT` | 5 |  |
| `ERROR_CODE_CANCELLED` | 6 |  |

### message `PairingOffer`

What a pairing QR code or link carries. Encoded as base64url in ferret://pair?o=<offer>.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `protocol_version` | `uint32` | 1 |  |
| `device_id` | `string` | 2 |  |
| `name` | `string` | 3 |  |
| `platform` | `Platform` | 4 |  |
| `hosts` | `repeated string` | 5 | Addresses the offering device listens on, such as "192.168.1.20". |
| `port` | `uint32` | 6 |  |
| `static_public_key` | `bytes` | 7 | X25519 static public key, 32 bytes. The scanner checks the Noise handshake's remote static key against it. |
| `secret` | `bytes` | 8 | One-time secret, 16 bytes, proving the scanner saw this offer. |
| `expires_at_ms` | `uint64` | 9 |  |

### message `PairingRequest`

Sent by the device that wants to pair, first thing on a new channel (feature "pairing").

| Field | Type | Number | Meaning |
|---|---|---|---|
| `device` | `DeviceInfo` | 1 |  |
| `proof` | `bytes` | 2 | HMAC-SHA256(offer secret, handshake hash) when pairing from an offer. Empty when pairing by comparing codes. |

### message `PairingResponse`

The answer to a PairingRequest (feature "pairing").

| Field | Type | Number | Meaning |
|---|---|---|---|
| `result` | `PairingResult` | 1 |  |
| `device` | `DeviceInfo` | 2 |  |
| `proof` | `bytes` | 3 | HMAC-SHA256(offer secret, handshake hash \|\| "response") so the scanner knows the offerer still holds the secret. |

### enum `PairingResult`

| Value | Number | Meaning |
|---|---|---|
| `PAIRING_RESULT_UNSPECIFIED` | 0 |  |
| `PAIRING_RESULT_ACCEPTED` | 1 |  |
| `PAIRING_RESULT_REJECTED` | 2 |  |
| `PAIRING_RESULT_EXPIRED` | 3 |  |
| `PAIRING_RESULT_BAD_PROOF` | 4 |  |

### message `Hello`

First envelope each side sends on a trusted session (feature "session").

| Field | Type | Number | Meaning |
|---|---|---|---|
| `device` | `DeviceInfo` | 1 |  |
| `features` | `repeated FeatureSupport` | 2 |  |
| `listen_port` | `uint32` | 3 | TCP port this device accepts connections on, for reconnecting later. |

### message `Ping`

Keeps a session alive and measures round trips (feature "session").

| Field | Type | Number | Meaning |
|---|---|---|---|
| `sent_at_ms` | `uint64` | 1 |  |

### message `Pong`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `ping_sent_at_ms` | `uint64` | 1 |  |

### message `Presence`

Says the user is active on this device right now, so others know where to show suggestions (feature "session").

| Field | Type | Number | Meaning |
|---|---|---|---|
| `user_active` | `bool` | 1 |  |
| `screen_on` | `bool` | 2 |  |
| `battery_percent` | `int32` | 3 | Battery level 0-100, or -1 when unknown or plugged desktop. |
| `charging` | `bool` | 4 |  |

### message `Goodbye`

Sent before a side closes on purpose, so the other one doesn't reconnect.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `reason` | `GoodbyeReason` | 1 |  |

### enum `GoodbyeReason`

| Value | Number | Meaning |
|---|---|---|
| `GOODBYE_REASON_UNSPECIFIED` | 0 |  |
| `GOODBYE_REASON_SHUTDOWN` | 1 |  |
| `GOODBYE_REASON_UNPAIRED` | 2 |  |
| `GOODBYE_REASON_DUPLICATE` | 3 |  |
