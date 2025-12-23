import 'package:tinode/src/models/access-mode.dart';
import 'package:tinode/src/models/def-acs.dart';

class TopicDescription {
  /// Topic creation date
  final DateTime? created;

  /// Topic update date
  DateTime? updated;

  /// Topic touched date
  final DateTime? touched;

  /// account status; included for `me` topic only, and only if
  /// the request is sent by a root-authenticated session.
  final String? status;

  /// Timestamp when status was last changed
  final DateTime? stateAt;

  /// topic's default access permissions; present only if the current user has 'S' permission
  DefAcs? defacs;

  /// Actual access permissions
  AccessMode? acs;

  /// Server-issued id of the last {data} message
  final int? seq;

  /// Id of the message user claims through {note} message to have read, optional
  final int? read;

  /// Like 'read', but received, optional
  final int? recv;

  /// in case some messages were deleted, the greatest ID
  /// of a deleted message, optional
  final int? clear;

  /// Application-defined payload writable by the system administration
  dynamic trusted;

  /// Application-defined data that's available to all topic subscribers
  dynamic public;

  /// Application-defined data that's available to the current user only
  dynamic private;

  /// Whether this is a channel topic
  final bool? isChan;

  /// Whether the topic/user is currently online
  final bool? online;

  bool? noForwarding;

  /// P2P only: other user's last online timestamp
  final DateTime? lastSeenTime;

  /// P2P only: other user's last user agent
  final String? lastSeenUserAgent;

  TopicDescription({
    this.created,
    this.updated,
    this.status,
    this.stateAt,
    this.defacs,
    this.acs,
    this.seq,
    this.read,
    this.recv,
    this.clear,
    this.trusted,
    this.public,
    this.private,
    this.isChan,
    this.online,
    this.noForwarding,
    this.touched,
    this.lastSeenTime,
    this.lastSeenUserAgent,
  });

  Map<String, dynamic> toJson() {
    return {
      'created': created?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'touched': touched?.toIso8601String(),
      'status': status,
      'stateAt': stateAt?.toIso8601String(),
      'defacs': defacs?.toJson(),
      'acs': acs?.jsonHelper(),
      'seq': seq,
      'read': read,
      'recv': recv,
      'clear': clear,
      'trusted': trusted,
      'public': public,
      'private': private,
      'isChan': isChan,
      'online': online,
    };
  }

  /// Create a new instance from received message
  static TopicDescription fromMessage(Map<String, dynamic> msg) {
    return TopicDescription(
      created: msg['created'] != null ? DateTime.tryParse(msg['created'] as String) : DateTime.now(),
      updated: msg['updated'] != null ? DateTime.tryParse(msg['updated'] as String) : DateTime.now(),
      acs: msg['acs'] != null ? AccessMode(msg['acs'] as Map<String, dynamic>) : null,
      trusted: msg['trusted'],
      public: msg['public'],
      private: msg['private'],
      status: msg['status'] as String?,
      stateAt: msg['state_at'] != null ? DateTime.tryParse(msg['state_at'] as String) : null,
      defacs: msg['defacs'] != null ? DefAcs.fromMessage(msg['defacs'] as Map<String, dynamic>) : null,
      seq: msg['seq'] as int?,
      read: msg['read'] as int?,
      recv: msg['recv'] as int?,
      clear: msg['clear'] as int?,
      isChan: msg['is_chan'] as bool?,
      online: msg['online'] as bool?,
      noForwarding: msg['noForwarding'] as bool?,
      touched: msg['touched'] != null ? DateTime.tryParse(msg['touched'] as String) : null,
      lastSeenTime: msg['seen'] != null && msg['seen']['when'] != null
          ? DateTime.tryParse((msg['seen'] as Map<String, dynamic>)['when'] as String)
          : null,
      lastSeenUserAgent: msg['seen'] != null
          ? (msg['seen'] as Map<String, dynamic>)['ua'] as String?
          : null,
    );
  }
}
