## 2.0.0

**Breaking Changes & Modernization** - This release is a major modernization of the SDK, forked from the original tinode/dart-sdk.

### New Features
- **Video Call Support** - Full WebRTC signaling with `VideoCallEvent` constants and `noteCall`/`noteData` methods
- **File Service** - HTTP-based file uploads with multipart support and progress callbacks
- **Auto-Reconnect** - `ConnectionService` with exponential backoff and jitter
- **Connection State** - Observable `ConnectionState` enum (disconnected, connecting, connected, reconnecting)

### Improvements
- **Dart 3.x Support** - Full migration to Dart SDK ^3.0.0
- **Complete Null Safety** - All code is now fully null-safe with explicit type casts
- **Tinode v0.25 Protocol** - Added missing fields from protobuf definitions:
  - `TopicDescription`: stateAt, trusted, isChan, online, lastSeenTime, lastSeenUserAgent
  - `TopicSubscription`: trusted, delId
  - `MetaMessage`: aux
- **Modern Dependencies** - Updated all dependencies to latest stable versions
- **Modern Linting** - Switched from pedantic to official `lints` package

### Dependencies
- `rxdart: ^0.28.0`
- `web_socket_channel: ^3.0.1`
- `get_it: ^8.0.2`
- `http: ^1.2.2`
- `http_parser: ^4.1.1`

### Testing
- 42 unit tests passing
- 0 analyzer errors or warnings

---

## 1.0.0-alpha.4

- Prevent duplicate service registration

## 1.0.0-alpha.3

- Topic set meta bug fixed 

## 1.0.0-alpha.2

- Fixed some bugs
- Upgrade dependency
- Null safety support
- Change dart sdk

## 1.0.0-alpha

- Initial version
