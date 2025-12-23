import 'dart:math';

import 'package:tindarts_sdk/src/models/topic-names.dart' as topic_names;
import 'package:tindarts_sdk/src/models/connection-options.dart';
import 'package:tindarts_sdk/src/models/access-mode.dart';
import 'package:tindarts_sdk/src/models/values.dart';

/// Initialize a random message Id
var messageId = Random().nextInt(0xFFFF) + 0xFFFF;

/// Helpers and tools to help you using tinode data
class Tools {
  /// Create base URL based on connection options
  static String makeBaseURL(ConnectionOptions config) {
    final url = (config.secure ?? false) ? 'wss://' : 'ws://';
    return '$url${config.host}/v0/channels?apikey=${config.apiKey}';
  }

  /// Get next message Id
  static String getNextUniqueId() {
    messageId++;
    return messageId.toString();
  }

  /// Json parser helper to read messages and converting data to native objects
  static Object? jsonParserHelper(Object? key, Object? value) {
    if (key == 'ts' && value is String && value.length >= 20 && value.length <= 24) {
      final date = DateTime.parse(value);
      return date;
    } else if (key == 'acs' && value is Map) {
      return AccessMode(value);
    }
    return value;
  }

  /// Returns the type of topic based on topic name
  static String? topicType(String topicName) {
    const types = {
      'me': 'me',
      'fnd': 'fnd',
      'grp': 'grp',
      'new': 'grp',
      'nch': 'grp',
      'chn': 'grp',
      'usr': 'p2p',
      'sys': 'sys',
    };

    if (topicName.length == 2) {
      return types[topicName.substring(0, 2)];
    }

    return types[topicName.substring(0, 3)];
  }

  /// Figure out if the topic name belongs to a group
  static bool isGroupTopicName(String topicName) {
    return Tools.topicType(topicName) == 'grp';
  }

  /// Figure out if the topic name belongs to a p2p topic
  static bool isP2PTopicName(String topicName) {
    return Tools.topicType(topicName) == 'p2p';
  }

  /// Figure out if the topic name belongs to a new group
  static bool isNewGroupTopicName(String topicName) {
    final prefix = topicName.substring(0, 3);
    return prefix == topic_names.TOPIC_NEW || prefix == topic_names.TOPIC_NEW_CHAN;
  }

  /// Figure out if the topic name belongs to a new channel
  static bool isChannelTopicName(String topicName) {
    final prefix = topicName.substring(0, 3);
    return prefix == topic_names.TOPIC_CHAN || prefix == topic_names.TOPIC_NEW_CHAN;
  }

  /// Create authorized URL
  static String makeAuthorizedURL(ConnectionOptions config, String token) {
    final base = makeBaseURL(config);
    return '$base&auth=token&secret=$token';
  }

  /// Trim whitespace, strip empty and duplicate elements elements
  /// If the result is an empty array, add a single element "\u2421" (Unicode Del character)
  static List<String> normalizeArray(List<String> arr) {
    var out = <String>[];

    // Trim, throw away very short and empty tags.
    for (var i = 0, l = arr.length; i < l; i++) {
      var t = arr[i];
      if (t != '') {
        t = t.trim().toLowerCase();
        if (t.length > 1) {
          out.add(t);
        }
      }
    }
    out.sort();
    out = out.toSet().toList();
      if (out.isEmpty) {
      // Add single tag with a Unicode Del character, otherwise an empty array
      // is ambiguous. The Del tag will be stripped by the server.
      out.add(DEL_CHAR);
    }
    return out;
  }
}
