# Tinode Dart SDK

<img align="right" height="100" width="200" src="https://user-images.githubusercontent.com/32099630/112821615-28e00500-909c-11eb-831d-9e16fdcc86c0.png">

A modern Dart SDK for the [Tinode](https://github.com/tinode/chat) instant messaging platform. This SDK implements the Tinode client-side protocol for building chat applications with Dart and Flutter.

> **Note:** This is a modernized fork of the [original tinode/dart-sdk](https://github.com/tinode/dart-sdk), updated for Dart 3.x, full null safety, and Tinode server v0.25.

## Features

- ✅ **Dart 3.x & Null Safety** - Fully migrated to modern Dart
- ✅ **Tinode Server v0.25** - Complete protocol support
- ✅ **Real-time Messaging** - WebSocket-based communication
- ✅ **Presence & Typing** - Online status and typing indicators
- ✅ **File Uploads** - Large file support with progress callbacks
- ✅ **Video Calls** - WebRTC call signaling support
- ✅ **Auto-Reconnect** - Exponential backoff with jitter
- ✅ **Cross-Platform** - Flutter mobile, desktop, web, and pure Dart

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  tindarts_sdk: ^2.0.0
```

Or run:

```bash
# For Dart applications
dart pub add tindarts_sdk

# For Flutter applications
flutter pub add tindarts_sdk
```

## Quick Start

```dart
import 'package:tindarts_sdk/tinode.dart';

void main() async {
  // Create connection options
  final options = ConnectionOptions(
    'api.tinode.co',      // Server host
    'YOUR_API_KEY',       // API key
    secure: true,         // Use WSS
  );

  // Initialize Tinode client
  final tinode = Tinode('MyApp/1.0', options, true);

  // Monitor connection state
  tinode.onConnectionStateChange.listen((state) {
    print('Connection: $state');
  });

  // Connect and authenticate
  await tinode.connect();
  await tinode.hello();
  await tinode.loginBasic('username', 'password', null);

  // Subscribe to 'me' topic for contacts & presence
  final me = tinode.getMeTopic();
  await me.subscribe(
    MetaGetBuilder(me)
        .withDesc(null)
        .withSub(null, null, null)
        .build(),
    null,
  );

  // Send a message
  final topic = tinode.getTopic('usr123456');
  await topic.subscribe(null, null);
  await topic.publishMessage('Hello, world!');
}
```

See [example/tinode_example.dart](example/tinode_example.dart) for a complete working example.

## Documentation

- [Tinode Server API](https://github.com/tinode/chat/blob/master/docs/API.md) - Protocol documentation
- [Video Call Flow](https://github.com/tinode/chat/blob/master/docs/call-establishment.md) - WebRTC integration

## Platform Support

| Platform | Status |
|----------|--------|
| Flutter Mobile (iOS/Android) | ✅ Supported |
| Flutter Desktop (macOS/Windows/Linux) | ✅ Supported |
| Flutter Web | ✅ Supported |
| Dart CLI/Server | ✅ Supported |

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

[Apache 2.0](LICENSE)

## Acknowledgments

This project is a fork of the original [tinode/dart-sdk](https://github.com/tinode/dart-sdk) by the Tinode team. The original SDK provided the foundation for this modernized version.