import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

import 'package:tindarts_sdk/src/models/message_status.dart' as message_status;
import 'package:tindarts_sdk/src/models/packet_types.dart' as packet_types;
import 'package:tindarts_sdk/src/services/packet_generator.dart';
import 'package:tindarts_sdk/src/models/server_messages.dart';
import 'package:tindarts_sdk/src/models/packet_data.dart';
import 'package:tindarts_sdk/src/models/packet.dart';

class Message {
  bool echo;
  int? _status;
  DateTime? ts;
  String? from;
  bool? cancelled;
  dynamic content;
  String? topicName;
  bool? noForwarding;

  late PacketGenerator _packetGenerator;

  PublishSubject<int> onStatusChange = PublishSubject<int>();

  Message(this.topicName, this.content, this.echo) {
    _status = message_status.statusNone;
    _packetGenerator = GetIt.I.get<PacketGenerator>();
  }

  Packet asPubPacket() {
    final packet = _packetGenerator.generate(packet_types.pub, topicName);
    final data = packet.data as PubPacketData;
    data.content = content;
    data.noecho = !echo;
    packet.data = data;
    return packet;
  }

  DataMessage asDataMessage(String from, int seq) {
    return DataMessage(
      content: content,
      from: from,
      noForwarding: false,
      head: {},
      hi: null,
      topic: topicName,
      seq: seq,
      ts: ts,
    );
  }

  void setStatus(int status) {
    _status = status;
    onStatusChange.add(status);
  }

  int? getStatus() {
    return _status;
  }

  void resetLocalValues() {
    ts = null;
    setStatus(message_status.statusNone);
  }
}
