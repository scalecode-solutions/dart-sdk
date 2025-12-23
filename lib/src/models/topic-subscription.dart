import 'package:tinode/src/models/topic-description.dart';
import 'package:tinode/src/models/access-mode.dart';

/// Info on when the peer was last online
class Seen {
  /// Timestamp
  DateTime? when;

  /// User agent of peer's client
  final String? ua;

  Seen({this.when, this.ua});

  static Seen fromMessages(Map<String, dynamic> msg) {
    return Seen(
      ua: msg['ua'] as String?,
      when: msg['when'] != null ? DateTime.parse(msg['when'] as String) : DateTime.now(),
    );
  }
}

/// Topic subscriber
class TopicSubscription {
  /// Id of the user this subscription
  String? user;

  /// Timestamp of the last change in the subscription, present only for
  /// requester's own subscriptions
  DateTime? updated;

  /// Timestamp of the last message in the topic (may also include
  /// other events in the future, such as new subscribers)
  DateTime? touched;

  DateTime? deleted;
  DateTime? created;

  /// User's access permissions
  AccessMode? acs;

  /// Id of the message user claims through {note} message
  int? read;

  /// Like 'read', but received, optional
  int? recv;

  /// In case some messages were deleted, the greatest Id of a deleted message, optional
  int? clear;

  /// Application-defined payload writable by the system administration
  dynamic trusted;

  /// Application-defined user's 'public' object, absent when querying P2P topics
  dynamic public;

  /// Application-defined user's 'private' object.
  dynamic private;

  /// current online status of the user; if this is a
  /// group or a p2p topic, it's user's online status in the topic,
  /// i.e. if the user is attached and listening to messages; if this
  /// is a response to a 'me' query, it tells if the topic is
  /// online; p2p is considered online if the other party is
  /// online, not necessarily attached to topic; a group topic
  /// is considered online if it has at least one active
  /// subscriber.
  bool? online;

  /// Topic this subscription describes
  ///
  /// can be used only when querying 'me' topic
  String? topic;

  /// Server-issued id of the last {data} message
  ///
  /// can be used only when querying 'me' topic
  int? seq;

  /// Messages are deleted up to this ID
  int? delId;

  /// If this is a P2P topic, info on when the peer was last online
  ///
  /// can be used only when querying 'me' topic
  Seen? seen;

  bool? noForwarding = false;

  String? mode;

  int? unread;

  TopicSubscription({
    this.user,
    this.updated,
    this.touched,
    this.acs,
    this.read,
    this.recv,
    this.clear,
    this.trusted,
    this.public,
    this.private,
    this.online,
    this.topic,
    this.seq,
    this.delId,
    this.seen,
    this.noForwarding,
    this.deleted,
    this.created,
    this.mode,
    this.unread,
  });

  static TopicSubscription fromMessage(Map<String, dynamic> msg) {
    return TopicSubscription(
      user: msg['user'] as String?,
      updated: msg['updated'] != null ? DateTime.parse(msg['updated'] as String) : null,
      touched: msg['touched'] != null ? DateTime.parse(msg['touched'] as String) : null,
      deleted: msg['deleted'] != null ? DateTime.parse(msg['deleted'] as String) : null,
      created: msg['created'] != null ? DateTime.parse(msg['created'] as String) : null,
      acs: msg['acs'] != null ? AccessMode(msg['acs'] as Map<String, dynamic>) : null,
      read: msg['read'] as int?,
      recv: msg['recv'] as int?,
      clear: msg['clear'] as int?,
      trusted: msg['trusted'],
      public: msg['public'],
      private: msg['private'],
      online: msg['online'] as bool?,
      topic: msg['topic'] as String?,
      seq: msg['seq'] as int?,
      delId: msg['del_id'] as int?,
      seen: msg['seen'] != null ? Seen.fromMessages(msg['seen'] as Map<String, dynamic>) : null,
      noForwarding: (msg['noForwarding'] as bool?) ?? false,
      mode: msg['mode'] as String?,
    );
  }

  TopicSubscription copy() {
    return TopicSubscription(
      user: user,
      updated: updated,
      touched: touched,
      deleted: deleted,
      created: created,
      acs: acs,
      read: read,
      recv: recv,
      clear: clear,
      trusted: trusted,
      public: public,
      private: private,
      online: online,
      topic: topic,
      seq: seq,
      delId: delId,
      seen: seen,
      noForwarding: noForwarding,
      mode: mode,
    );
  }

  TopicDescription asDesc() {
    return TopicDescription(
      acs: acs,
      clear: clear,
      created: created,
      noForwarding: noForwarding,
      trusted: trusted,
      private: private,
      public: public,
      read: read,
      recv: recv,
      seq: seq,
      touched: touched,
      updated: updated,
    );
  }
}
