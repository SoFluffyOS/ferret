# Protocol reference

Generated from `proto/` by `scripts/docs.sh reference`. Do not edit by hand.

Every message travels inside an `Envelope` (see `ferret.v1`), whose `feature` field names the feature and whose `type` field is the full message name below.

## `ferret.actions.v1`

### enum `ActionKind`

What an action does on the computer that offers it.

| Value | Number | Meaning |
|---|---|---|
| `ACTION_KIND_UNSPECIFIED` | 0 |  |
| `ACTION_KIND_SLEEP` | 1 | Puts the computer to sleep. |
| `ACTION_KIND_RESTART` | 2 | Restarts the computer, after a countdown its owner can cancel. |
| `ACTION_KIND_SHUT_DOWN` | 3 | Turns the computer off, after a countdown its owner can cancel. |
| `ACTION_KIND_MUTE` | 4 | Mutes the sound, or brings it back when it is muted. |
| `ACTION_KIND_VOLUME_UP` | 5 |  |
| `ACTION_KIND_VOLUME_DOWN` | 6 |  |
| `ACTION_KIND_CUSTOM` | 7 | A command its owner defined on the computer. The command line never leaves that computer: only `id` and `title` do. |

### message `Action`

Something a computer can do when a paired device asks.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | Stays the same for as long as the action exists: `sleep`, `restart`, `shut_down`, `mute`, `volume_up`, `volume_down`, or `custom.<random>` for the owner's own. |
| `kind` | `ActionKind` | 2 |  |
| `title` | `string` | 3 | The owner's name for a custom action. Empty for the others: the asking device words those itself, in its own language. |
| `confirm` | `bool` | 4 | The asking device should confirm with its user before sending `RunAction`, because the computer is out of reach afterwards. |

### message `ActionList`

Every action a computer offers the receiver right now. Sent without expecting a reply when a session opens and whenever the list changes. A device that never got one shows no actions.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `actions` | `repeated Action` | 1 |  |

### message `RunAction`

Asks the computer to run one of its actions. Expects a `RunActionReply`, which can take a minute: the computer may ask its owner first, and counts down before it restarts or shuts down.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | An `Action.id` from the computer's `ActionList`. Never a command line. |

### enum `RunResult`

How a `RunAction` went.

| Value | Number | Meaning |
|---|---|---|
| `RUN_RESULT_UNSPECIFIED` | 0 |  |
| `RUN_RESULT_DONE` | 1 | It ran. For sleep, restart and shut down: it is about to. |
| `RUN_RESULT_DENIED` | 2 | The owner said no on the computer. |
| `RUN_RESULT_NOT_ANSWERED` | 3 | Nobody answered the question on the computer in time. |
| `RUN_RESULT_BUSY` | 4 | The computer is asking about, or counting down, another request. |
| `RUN_RESULT_TURNED_OFF` | 5 | Actions are turned off on the computer. |
| `RUN_RESULT_UNKNOWN_ACTION` | 6 | No action has that id, such as one its owner removed. |
| `RUN_RESULT_FAILED` | 7 | It was tried and didn't work. For a custom action: it couldn't start, or ended with a non-zero `exit_code`. |
| `RUN_RESULT_CANCELLED` | 8 | Someone cancelled the countdown on the computer. |
| `RUN_RESULT_TIMED_OUT` | 9 | A custom action ran longer than the computer allows and was stopped. |

### message `RunActionReply`

The reply to `RunAction`. What a custom action printed stays on the computer.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `result` | `RunResult` | 1 |  |
| `exit_code` | `optional sint32` | 2 | How a custom action's command ended. Only set when it ran to its end. |

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
| `folder` | `string` | 5 | The folder the file sits in when a whole folder is sent, relative and separated by "/": "Photos" or "Photos/2024". The first part is the folder that was sent. Empty for a file sent on its own. Senders only fill it for receivers whose drop FeatureSupport has the "folders" flag; receivers clean every part and never write outside their receive folder. |
| `modified_ms` | `int64` | 6 | When the file was last modified, in milliseconds since the Unix epoch, or 0 when unknown. Receivers keep it where the platform allows. |

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

## `ferret.mirroring.v1`

### enum `Codec`

How the pictures are encoded.

| Value | Number | Meaning |
|---|---|---|
| `CODEC_UNSPECIFIED` | 0 |  |
| `CODEC_H264` | 1 | H.264 video. `Frame.data` is one access unit in Annex-B form. |
| `CODEC_JPEG` | 2 | A JPEG picture per frame, for viewers without a video decoder. Fewer frames per second and a smaller picture. |

### message `StartRequest`

Asks the source to show its screen. Expects a `StartPending` or `StartDeny` reply. After `StartPending`, the source sends `StartAccept` or `StartDeny` later, without expecting a reply.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `version` | `uint32` | 1 | The version of these messages the viewer speaks. |
| `codecs` | `repeated Codec` | 2 | What the viewer can decode, best first. |
| `max_width` | `uint32` | 3 | The largest picture the viewer wants, in pixels. 0 leaves it to the source, which never sends more than 1920 on the long side. |
| `max_height` | `uint32` | 4 |  |
| `max_fps` | `uint32` | 5 | 0 leaves it to the source. |

### message `StartPending`

The source is asking its owner. The answer follows as `StartAccept` or `StartDeny`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `timeout_seconds` | `uint32` | 1 | How long the source waits for its owner before it denies with `DENY_REASON_TIMEOUT`. |

### message `StartAccept`

The owner said yes. A `StreamConfig` and `Frame`s follow until either side sends `Stop`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `version` | `uint32` | 1 | The version of these messages the source speaks. |
| `codec` | `Codec` | 2 | The codec the source picked from `StartRequest.codecs`. |

### enum `DenyReason`

Why a source said no.

| Value | Number | Meaning |
|---|---|---|
| `DENY_REASON_UNSPECIFIED` | 0 |  |
| `DENY_REASON_DENIED` | 1 | Its owner said no on the system prompt. |
| `DENY_REASON_TIMEOUT` | 2 | Nobody answered on the source in time. |
| `DENY_REASON_BUSY` | 3 | It already shares its screen, or is asking its owner, for another device. |
| `DENY_REASON_UNSUPPORTED` | 4 | This device can't capture its screen. |
| `DENY_REASON_TURNED_OFF` | 5 | Its owner turned screen mirroring off. |
| `DENY_REASON_VERSION` | 6 | The viewer speaks a newer version. |
| `DENY_REASON_NO_CODEC` | 7 | The source can't encode any of `StartRequest.codecs`. |
| `DENY_REASON_CANNOT_ASK` | 8 | The source couldn't show the question, such as when its app is in the background and may not post notices. |
| `DENY_REASON_FAILED` | 9 | Capturing or encoding failed to start. |

### message `StartDeny`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `reason` | `DenyReason` | 1 |  |

### message `StreamConfig`

How to decode the frames that follow. The source sends it before the first frame, and again with a new `config_id` when the picture changes, such as when the phone is rotated.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `config_id` | `uint32` | 1 | Goes up by one with every new config in a mirroring session. |
| `codec` | `Codec` | 2 |  |
| `width` | `uint32` | 3 | Size of the picture in pixels, as it should be shown. |
| `height` | `uint32` | 4 |  |
| `rotation` | `uint32` | 5 | How the source's screen is rotated, in degrees clockwise: 0, 90, 180 or 270. The picture is already upright; this is for information. |
| `fps` | `uint32` | 6 | The most frames per second the source sends. |
| `sps` | `bytes` | 7 | H.264 only: the sequence and picture parameter sets, each one NAL unit without a start code. |
| `pps` | `bytes` | 8 |  |

### message `Frame`

One picture. Sent without expecting a reply.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `config_id` | `uint32` | 1 | The `StreamConfig` this frame belongs to. A viewer drops frames of a config it hasn't seen. |
| `sequence` | `uint64` | 2 | Goes up by one with every frame the source produced, including those it dropped, so a gap tells the viewer how many were dropped. |
| `pts_us` | `int64` | 3 | When the picture was captured, in microseconds on the source's own clock. Only differences mean something. |
| `keyframe` | `bool` | 4 | The frame decodes on its own. After a gap, a viewer waits for one. |
| `data` | `bytes` | 5 | H.264: one access unit in Annex-B form. JPEG: the picture. |

### message `KeyframeRequest`

The viewer lost its place, such as after a decoding error, and asks for a frame that decodes on its own. Sent without expecting a reply.


### enum `KeyframeRequest.StopReason`

Why mirroring ended.

| Value | Number | Meaning |
|---|---|---|
| `STOP_REASON_UNSPECIFIED` | 0 |  |
| `STOP_REASON_VIEWER_DONE` | 1 | The viewer is done, such as when its mirror page closed, or it gave up waiting for the answer. |
| `STOP_REASON_STOPPED_ON_SOURCE` | 2 | Someone on the source pressed Stop. |
| `STOP_REASON_SYSTEM_ENDED` | 3 | The source's system ended the capture, such as when the phone was locked. |
| `STOP_REASON_TURNED_OFF` | 4 | The source's owner turned screen mirroring off. |
| `STOP_REASON_FAILED` | 5 | Capturing or encoding stopped working. |
| `STOP_REASON_NOT_MIRRORING` | 6 | A frame or request arrived for a mirroring session that isn't running. |

### message `KeyframeRequest.Stop`

Ends mirroring. Either side sends it, without expecting a reply. The source stops capturing at once.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `reason` | `StopReason` | 1 |  |

### message `KeyframeRequest.SourceState`

Something about the source's screen changed while it is shared.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `screen_off` | `bool` | 1 | The screen is off: no new frames until it is on again. |

### message `KeyframeRequest.Stats`

How the stream is doing. The viewer sends one about every second; the source answers each with its own, and uses them to pick the bitrate.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `sent_at_ms` | `int64` | 1 | When this was sent, in milliseconds on the sender's own clock. |
| `echo_sent_at_ms` | `int64` | 2 | Source only: `sent_at_ms` of the viewer's `Stats` this answers, so the viewer can measure the round trip. |
| `fps` | `uint32` | 3 | Viewer: frames shown in the last second. Source: frames sent. |
| `dropped_frames` | `uint32` | 4 | Frames dropped in the last second: by the source because the connection backed up, or by the viewer because decoding fell behind. |
| `bitrate_kbps` | `uint32` | 5 | Source only: what the encoder aims for right now, in kilobits per second. 0 for JPEG. |

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
| `text_hidden` | `bool` | 10 | The source held back the text (and a title that carried it) because it looks like a one-time code, such as a sign-in or bank code. Receivers say so instead of showing an empty line. |

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

### enum `AppFilter`

Which apps the source mirrors.

| Value | Number | Meaning |
|---|---|---|
| `APP_FILTER_UNSPECIFIED` | 0 | Sent by sources that predate the filter: they mirror `allowed_packages` only, as `APP_FILTER_ONLY`. |
| `APP_FILTER_ALL` | 1 | Every app. |
| `APP_FILTER_ALL_EXCEPT` | 2 | Every app except `excluded_packages`. |
| `APP_FILTER_ONLY` | 3 | Only `allowed_packages`. |

### message `MirrorSettings`

How the source mirrors notifications.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `enabled` | `bool` | 1 | The person turned mirroring on. |
| `access_granted` | `bool` | 2 | The platform lets the source read notifications. |
| `skip_while_using` | `bool` | 3 | Mirroring pauses while the source is in use (screen on and unlocked). |
| `allowed_packages` | `repeated string` | 4 | The apps picked for `APP_FILTER_ONLY`. Kept while another filter is active, so switching back restores them. |
| `app_filter` | `AppFilter` | 5 | Which apps are mirrored. |
| `excluded_packages` | `repeated string` | 6 | The apps muted for `APP_FILTER_ALL_EXCEPT`. Kept while another filter is active. |

### message `MirrorSettingsRequest`

Asks the source for its `MirrorSettings`. Expects a `MirrorSettings` reply.


### message `MirrorSettingsRequest.AppEntry`

An app the person can pick in the app list.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `package` | `string` | 1 |  |
| `name` | `string` | 2 |  |
| `icon_png` | `bytes` | 3 | A small PNG of the app's icon. |
| `allowed` | `bool` | 4 | Its notifications are mirrored under the current filter. |
| `is_messaging` | `bool` | 5 | A messaging app, such as Signal or WhatsApp. |
| `last_posted_ms` | `int64` | 6 | When the app last posted a notification the source saw, in the source device's clock. 0 when unknown. |

### message `MirrorSettingsRequest.AppListRequest`

Asks the source for its apps. Expects an `AppListResponse` reply.


### message `MirrorSettingsRequest.AppListRequest.AppListResponse`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `apps` | `repeated AppEntry` | 1 |  |

### message `MirrorSettingsRequest.AppListRequest.AppChoice`

Turns one app on or off: under `APP_FILTER_ALL_EXCEPT` it changes `excluded_packages`, under `APP_FILTER_ONLY` `allowed_packages`. Turning an app off under `APP_FILTER_ALL` switches to `APP_FILTER_ALL_EXCEPT`.

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
| `app_filter` | `optional AppFilter` | 3 | Applied before `apps`. Left out to keep the current filter. |

## `ferret.remote_input.v1`

### message `ControlRequest`

Asks the computer for control. Expects a `ControlPending`, `ControlGrant` or `ControlDeny` reply. After `ControlPending`, the computer sends the `ControlGrant` or `ControlDeny` later, without expecting a reply.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `version` | `uint32` | 1 | The version of these messages the controller speaks. |

### message `ControlPending`

The computer is asking its owner. The answer follows as `ControlGrant` or `ControlDeny`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `timeout_seconds` | `uint32` | 1 | How long the computer waits for its owner before it denies with `DENY_REASON_TIMEOUT`. |

### message `ControlGrant`

The controller may send `InputBatch`es until either side sends `ControlStop`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `version` | `uint32` | 1 | The version of these messages the computer speaks. |
| `always` | `bool` | 2 | The computer's owner allowed this device for good, not just this once. |

### enum `DenyReason`

Why a computer said no.

| Value | Number | Meaning |
|---|---|---|
| `DENY_REASON_UNSPECIFIED` | 0 |  |
| `DENY_REASON_DENIED` | 1 | Its owner said no. |
| `DENY_REASON_TIMEOUT` | 2 | Nobody answered on the computer in time. |
| `DENY_REASON_BUSY` | 3 | Another device controls it, or asks to, right now. |
| `DENY_REASON_NEEDS_PERMISSION` | 4 | The system permission to control input is missing, such as Accessibility on macOS. The computer shows its owner how to allow it. |
| `DENY_REASON_UNSUPPORTED` | 5 | This computer has no way to inject input, such as Linux without uinput access, xdotool or ydotool. |
| `DENY_REASON_TURNED_OFF` | 6 | Its owner turned remote input off. |
| `DENY_REASON_VERSION` | 7 | The controller speaks a newer major version. |

### message `ControlDeny`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `reason` | `DenyReason` | 1 |  |

### enum `StopReason`

Why control ended.

| Value | Number | Meaning |
|---|---|---|
| `STOP_REASON_UNSPECIFIED` | 0 |  |
| `STOP_REASON_CONTROLLER_DONE` | 1 | The controller is done, such as when its touchpad page closed. |
| `STOP_REASON_STOPPED_ON_HOST` | 2 | Someone on the computer pressed Stop. |
| `STOP_REASON_IDLE` | 3 | Nothing happened for a long time. |
| `STOP_REASON_REVOKED` | 4 | The computer's owner revoked this device, or turned remote input off. |
| `STOP_REASON_NOT_CONTROLLING` | 5 | Input arrived from a device that has no control right now. |
| `STOP_REASON_FAILED` | 6 | The computer can no longer inject input, such as when its owner turned Accessibility access off. |

### message `ControlStop`

Ends control. Either side sends it, without expecting a reply. The computer releases every button and key still held.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `reason` | `StopReason` | 1 |  |

### enum `MouseButton`

A pointer button.

| Value | Number | Meaning |
|---|---|---|
| `MOUSE_BUTTON_UNSPECIFIED` | 0 |  |
| `MOUSE_BUTTON_LEFT` | 1 |  |
| `MOUSE_BUTTON_RIGHT` | 2 |  |
| `MOUSE_BUTTON_MIDDLE` | 3 |  |

### enum `Key`

A key, by what it is rather than by any platform's code. Text goes as `TextInput`; keys are for shortcuts and keys that type nothing.

| Value | Number | Meaning |
|---|---|---|
| `KEY_UNSPECIFIED` | 0 |  |
| `KEY_ENTER` | 1 |  |
| `KEY_BACKSPACE` | 2 |  |
| `KEY_DELETE` | 3 |  |
| `KEY_TAB` | 4 |  |
| `KEY_ESCAPE` | 5 |  |
| `KEY_SPACE` | 6 |  |
| `KEY_ARROW_LEFT` | 7 |  |
| `KEY_ARROW_RIGHT` | 8 |  |
| `KEY_ARROW_UP` | 9 |  |
| `KEY_ARROW_DOWN` | 10 |  |
| `KEY_HOME` | 11 |  |
| `KEY_END` | 12 |  |
| `KEY_PAGE_UP` | 13 |  |
| `KEY_PAGE_DOWN` | 14 |  |
| `KEY_MEDIA_PLAY_PAUSE` | 20 |  |
| `KEY_MEDIA_NEXT` | 21 |  |
| `KEY_MEDIA_PREVIOUS` | 22 |  |
| `KEY_VOLUME_UP` | 23 |  |
| `KEY_VOLUME_DOWN` | 24 |  |
| `KEY_VOLUME_MUTE` | 25 |  |
| `KEY_F1` | 31 |  |
| `KEY_F2` | 32 |  |
| `KEY_F3` | 33 |  |
| `KEY_F4` | 34 |  |
| `KEY_F5` | 35 |  |
| `KEY_F6` | 36 |  |
| `KEY_F7` | 37 |  |
| `KEY_F8` | 38 |  |
| `KEY_F9` | 39 |  |
| `KEY_F10` | 40 |  |
| `KEY_F11` | 41 |  |
| `KEY_F12` | 42 |  |
| `KEY_A` | 65 | Letters and digits, for shortcuts such as Ctrl+C. |
| `KEY_B` | 66 |  |
| `KEY_C` | 67 |  |
| `KEY_D` | 68 |  |
| `KEY_E` | 69 |  |
| `KEY_F` | 70 |  |
| `KEY_G` | 71 |  |
| `KEY_H` | 72 |  |
| `KEY_I` | 73 |  |
| `KEY_J` | 74 |  |
| `KEY_K` | 75 |  |
| `KEY_L` | 76 |  |
| `KEY_M` | 77 |  |
| `KEY_N` | 78 |  |
| `KEY_O` | 79 |  |
| `KEY_P` | 80 |  |
| `KEY_Q` | 81 |  |
| `KEY_R` | 82 |  |
| `KEY_S` | 83 |  |
| `KEY_T` | 84 |  |
| `KEY_U` | 85 |  |
| `KEY_V` | 86 |  |
| `KEY_W` | 87 |  |
| `KEY_X` | 88 |  |
| `KEY_Y` | 89 |  |
| `KEY_Z` | 90 |  |
| `KEY_DIGIT_0` | 100 |  |
| `KEY_DIGIT_1` | 101 |  |
| `KEY_DIGIT_2` | 102 |  |
| `KEY_DIGIT_3` | 103 |  |
| `KEY_DIGIT_4` | 104 |  |
| `KEY_DIGIT_5` | 105 |  |
| `KEY_DIGIT_6` | 106 |  |
| `KEY_DIGIT_7` | 107 |  |
| `KEY_DIGIT_8` | 108 |  |
| `KEY_DIGIT_9` | 109 |  |

### enum `Modifier`

A key held with another key. `MODIFIER_META` is Command on macOS, the Windows key on Windows and Super on Linux.

| Value | Number | Meaning |
|---|---|---|
| `MODIFIER_UNSPECIFIED` | 0 |  |
| `MODIFIER_SHIFT` | 1 |  |
| `MODIFIER_CONTROL` | 2 |  |
| `MODIFIER_ALT` | 3 |  |
| `MODIFIER_META` | 4 |  |

### message `PointerMove`

Moves the pointer by a distance in logical pixels of the computer's screen, after the controller applied its speed and acceleration.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `dx` | `sint32` | 1 |  |
| `dy` | `sint32` | 2 |  |

### message `ButtonEvent`

Presses (`pressed`) or releases a pointer button. A click is a press and a release; a drag is a press, moves, then a release.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `button` | `MouseButton` | 1 |  |
| `pressed` | `bool` | 2 |  |

### message `Scroll`

Scrolls by a distance in logical pixels. Positive `dy` scrolls toward the end of the page (down), positive `dx` to the right.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `dx` | `sint32` | 1 |  |
| `dy` | `sint32` | 2 |  |

### message `KeyEvent`

Presses (`pressed`) or releases a key, with the modifiers held for it.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `key` | `Key` | 1 |  |
| `pressed` | `bool` | 2 |  |
| `modifiers` | `repeated Modifier` | 3 |  |

### message `TextInput`

Types text as it is, whatever the computer's keyboard layout.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `text` | `string` | 1 |  |

### message `InputEvent`

One input action.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `move` | `PointerMove` | 1 |  |
| `button` | `ButtonEvent` | 2 |  |
| `scroll` | `Scroll` | 3 |  |
| `key` | `KeyEvent` | 4 |  |
| `text` | `TextInput` | 5 |  |

### message `InputBatch`

Input from the controller, in order, without expecting a reply. The controller sends at most about 60 a second and merges pointer moves in between, so a batch holds what happened since the last one.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `events` | `repeated InputEvent` | 1 |  |

### message `LockRequest`

Asks the computer to lock its screen now, as its own Lock Screen command does. Send it only to a computer whose `FeatureSupport` flags for this feature include "lock"; older computers don't know it. Expects a `LockReply`. The first time per device the computer asks its owner, so the reply can take as long as its consent timeout (60 seconds).


### enum `LockRequest.LockResult`

What came of a `LockRequest`.

| Value | Number | Meaning |
|---|---|---|
| `LOCK_RESULT_UNSPECIFIED` | 0 |  |
| `LOCK_RESULT_LOCKED` | 1 | The screen is locked. |
| `LOCK_RESULT_DENIED` | 2 | Its owner said no. |
| `LOCK_RESULT_TIMEOUT` | 3 | Nobody answered on the computer in time. |
| `LOCK_RESULT_BUSY` | 4 | The computer is asking its owner about another device right now. |
| `LOCK_RESULT_TURNED_OFF` | 5 | Its owner turned remote input off. |
| `LOCK_RESULT_FAILED` | 6 | The computer tried and couldn't lock. |

### message `LockRequest.LockReply`

| Field | Type | Number | Meaning |
|---|---|---|---|
| `result` | `LockResult` | 1 |  |

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
| `oldest_protocol_version` | `uint32` | 8 | Lowest protocol version the device still speaks. Zero means the same as protocol_version. Two devices talk only while their ranges overlap; each side works out which one must update from the two ranges alone. |

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
| `commitment` | `bytes` | 3 | SHA-256 of the requester's nonce, when pairing by comparing codes. It fixes the nonce before the answerer picks its own, so neither side can steer the six digits (see PairingChallenge). |
| `also_devices` | `repeated string` | 4 | Names of the requester's other devices, which the answerer will be connected to as well (see Introduce). Shown on the answerer's prompt. |

### message `PairingChallenge`

Pairing by comparing codes, step 2: the answerer's 16-byte nonce, sent once it holds the requester's commitment (feature "pairing").

| Field | Type | Number | Meaning |
|---|---|---|---|
| `nonce` | `bytes` | 1 |  |

### message `PairingReveal`

Pairing by comparing codes, step 3: the requester's 16-byte nonce, which must hash to its commitment (feature "pairing"). Both sides then show HMAC-SHA256(handshake hash, "ferret-compare" || requester nonce || answerer nonce) as six digits.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `nonce` | `bytes` | 1 |  |

### message `PairingConfirm`

Pairing by comparing codes: what the requester's user said after seeing the six digits (feature "pairing"). The answerer trusts the requester only after its own user agreed and this arrived with accepted = true.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `accepted` | `bool` | 1 |  |

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
| `PAIRING_RESULT_TIMED_OUT` | 5 | Nobody answered the prompt in time. |

### message `Introduce`

Tells a paired device about the sender's other paired devices, so one pairing joins them all (feature "pairing", on a trusted session only). The session's Noise handshake proves who sends it; a device accepts it only from a device it already trusts, and only while its user lets pairings be shared. Devices that don't know the message ignore it.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `devices` | `repeated IntroducedDevice` | 1 |  |
| `forgotten` | `repeated ForgottenDevice` | 2 | Devices the user removed from all their devices. |

### message `IntroducedDevice`

One device the sender trusts.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 | Must be the id derived from static_public_key, or the entry is dropped. |
| `name` | `string` | 2 |  |
| `platform` | `Platform` | 3 |  |
| `form_factor` | `FormFactor` | 4 |  |
| `static_public_key` | `bytes` | 5 | X25519 static public key, 32 bytes. The receiver trusts exactly this key. |
| `host` | `string` | 6 | Where the sender last reached the device, to connect without waiting for discovery. May be empty. |
| `port` | `uint32` | 7 |  |
| `paired_at_ms` | `uint64` | 8 | When the user paired the device, passed along unchanged. An entry older than the receiver's record of forgetting the device is dropped. |

### message `ForgottenDevice`

A device to stop trusting, with when the user removed it.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `id` | `string` | 1 |  |
| `forgotten_at_ms` | `uint64` | 2 |  |

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
| `away` | `bool` | 5 | A computer whose screen is locked or showing another account: this device is connected, but nobody is at it to see what arrives. |

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

### message `WakeInfo`

How to wake a computer from sleep with a Wake-on-LAN magic packet. A computer shares it only with its paired devices (feature "wake"), when a session opens and again when its network cards change. A MAC address identifies the computer, so it never goes anywhere else.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `interfaces` | `repeated WakeInterface` | 1 | Its wired and Wi-Fi network cards that have an IPv4 address, wired first. Virtual cards (VPNs, bridges, containers) are left out. |

### message `WakeInterface`

One network card a computer can be woken through.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `mac` | `bytes` | 1 | Hardware (MAC) address, 6 bytes. |
| `address` | `string` | 2 | Its IPv4 address on that network, such as "192.168.1.20". |
| `broadcast` | `string` | 3 | That network's broadcast address, such as "192.168.1.255". |
| `link` | `WakeLink` | 4 |  |
| `setting` | `WakeSetting` | 5 | Whether the card is set to wake on a magic packet, when the computer can tell. |

### enum `WakeLink`

How a network card is connected. Wired cards wake reliably once Wake-on-LAN is on; few Wi-Fi cards wake at all.

| Value | Number | Meaning |
|---|---|---|
| `WAKE_LINK_UNSPECIFIED` | 0 |  |
| `WAKE_LINK_WIRED` | 1 |  |
| `WAKE_LINK_WIFI` | 2 |  |

### enum `WakeSetting`

What the computer's own settings say about waking on a magic packet.

| Value | Number | Meaning |
|---|---|---|
| `WAKE_SETTING_UNSPECIFIED` | 0 | It couldn't tell, such as without permission to ask the driver. |
| `WAKE_SETTING_ON` | 1 |  |
| `WAKE_SETTING_OFF` | 2 |  |

## `ferret.wake.v1`

### message `WakeRequest`

Asks a device that is on to send the magic packet for another of the user's devices, for when the asking one can't reach that network itself (an iPhone may not broadcast, a phone may be on mobile data). Expects a `WakeReply`. The receiver acts only for a device it is paired with too.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `device_id` | `string` | 1 | The device to wake. |
| `info` | `ferret.v1.WakeInfo` | 2 | What the asking device knows about how to wake it. The receiver uses its own copy first. |
| `last_address` | `string` | 3 | The address the asking device last reached it at, such as "192.168.1.20". |

### message `WakeReply`

What came of a `WakeRequest`.

| Field | Type | Number | Meaning |
|---|---|---|---|
| `result` | `WakeResult` | 1 |  |

### enum `WakeResult`

| Value | Number | Meaning |
|---|---|---|
| `WAKE_RESULT_UNSPECIFIED` | 0 |  |
| `WAKE_RESULT_SENT` | 1 | The magic packet went out. Whether the device wakes shows when it connects. |
| `WAKE_RESULT_NOT_PAIRED` | 2 | The receiver isn't paired with that device, so it won't wake it. |
| `WAKE_RESULT_RELAY_OFF` | 3 | Its owner turned off waking devices for others on the receiver. |
| `WAKE_RESULT_NO_INFO` | 4 | Neither side knows the device's network card. |
| `WAKE_RESULT_FAILED` | 5 | Sending failed, such as with no network. |
