/// Tinode Dart SDK Example
///
/// This example demonstrates how to use the Tinode Dart SDK to:
/// - Connect to a Tinode server
/// - Create an account or log in
/// - Subscribe to the 'me' topic
/// - Send and receive messages
///
/// To run this example:
///   dart run example/tinode_example.dart
///
/// Note: Set the environment variables TINODE_USER and TINODE_PASS for login,
/// or leave them unset to create a new account.
library;

import 'dart:io';

import 'package:tindarts_sdk/tinode.dart';

void main() async {
  // Connection options for sandbox.tinode.co
  // ConnectionOptions(host, apiKey, {secure})
  final options = ConnectionOptions(
    'api.tinode.co',
    'AQEAAAABAAD_rAp4DJh05a1HAwFT3A6K',
    secure: true,
  );

  // Create Tinode instance with logging enabled
  final tinode = Tinode('TinodeDartExample/1.0', options, true);

  // Monitor connection state changes
  tinode.onConnectionStateChange.listen((state) {
    print('📡 Connection state: $state');
  });

  // Handle incoming messages
  tinode.onMessage.listen((message) {
    if (message.data != null) {
      print('📨 Received data message: ${message.data?.content}');
    }
    if (message.pres != null) {
      print('👁 Presence: ${message.pres?.what} from ${message.pres?.src}');
    }
  });

  // Handle disconnection
  tinode.onDisconnect.listen((_) {
    print('❌ Disconnected from server');
  });

  try {
    // Connect to the server
    print('Connecting to api.tinode.co...');
    await tinode.connect();
    print('✅ Connected!');

    // Send hello message to get server info
    final serverInfo = await tinode.hello();
    print('📋 Server build: ${serverInfo.params?['build']}');
    print('   Max message size: ${tinode.getServerInfo().maxMessageSize}');
    print('   Max file upload: ${tinode.getServerInfo().maxFileUploadSize}');

    // Get credentials from environment or use default test values
    final username = Platform.environment['TINODE_USER'];
    final password = Platform.environment['TINODE_PASS'];

    if (username != null && password != null) {
      // Login with existing credentials
      print('Logging in as $username...');
      final ctrl = await tinode.loginBasic(username, password, null);
      print('✅ Logged in! User ID: ${ctrl.params?['user']}');
    } else {
      // Create a new account for testing
      print('Creating new account...');
      final testUser = 'darttest${DateTime.now().millisecondsSinceEpoch}';
      const testPass = 'password123';

      try {
        // createAccountBasic(username, password, login, params)
        final ctrl = await tinode.createAccountBasic(
          testUser,
          testPass,
          true, // login after creating
          AccountParams(
            public: {'fn': 'Dart SDK Test User'},
            tags: ['dart', 'sdk', 'test'],
          ),
        );
        print('✅ Account created! Response: $ctrl');
        print('   Username: $testUser');
        print('   (You can now set TINODE_USER=$testUser and TINODE_PASS=$testPass to login next time)');
      } catch (e) {
        print('⚠️ Account creation failed: $e');
        print('   Try setting TINODE_USER and TINODE_PASS environment variables');
        tinode.disconnect();
        exit(1);
      }
    }

    // Get the 'me' topic to receive contacts and presence updates
    final me = tinode.getMeTopic();

    // Set up message handlers for 'me' topic
    me.onMeta.listen((meta) {
      if (meta.sub != null) {
        print('📒 Contacts updated: ${meta.sub?.length} contacts');
        for (final contact in meta.sub ?? <TopicSubscription>[]) {
          print('   - ${contact.user}: ${contact.public?['fn'] ?? 'Unknown'}');
        }
      }
    });

    me.onPres.listen((pres) {
      print('👤 Presence update: ${pres.what} from ${pres.src}');
    });

    // Subscribe to 'me' topic
    print('Subscribing to "me" topic...');
    await me.subscribe(
      MetaGetBuilder(me)
          .withDesc(null) // Get topic description
          .withSub(null, null, null) // Get subscriptions
          .withData(null, null, 20) // Get last 20 messages
          .build(),
      null,
    );
    print('✅ Subscribed to "me" topic');

    // Display some information about the current user
    print('');
    print('=== Current User Info ===');
    print('User ID: ${tinode.getCurrentUserId()}');
    print('Contacts: ${me.contacts.length}');

    // Example: List all contacts
    print('');
    print('=== Contacts ===');
    for (final contact in me.contacts) {
      print('  ${contact.user}: ${contact.public?['fn'] ?? 'Unknown'}');
      if (contact.online == true) {
        print('    (online)');
      }
    }

    // Keep the connection alive for a bit to receive any presence updates
    print('');
    print('Listening for updates (press Ctrl+C to exit)...');

    // Demonstrate video call event constants
    print('');
    print('=== Available Video Call Events ===');
    print('  ${VideoCallEvent.invite}');
    print('  ${VideoCallEvent.ringing}');
    print('  ${VideoCallEvent.accept}');
    print('  ${VideoCallEvent.answer}');
    print('  ${VideoCallEvent.offer}');
    print('  ${VideoCallEvent.iceCandidate}');
    print('  ${VideoCallEvent.hangUp}');

    // Wait for user to cancel
    await ProcessSignal.sigint.watch().first;
    print('');
    print('Disconnecting...');
    tinode.disconnect();
    print('👋 Goodbye!');
  } catch (e, stack) {
    print('❌ Error: $e');
    print(stack);
    tinode.disconnect();
    exit(1);
  }
}
