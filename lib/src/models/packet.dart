import 'package:tindarts_sdk/src/models/packet_data.dart';

class Packet {
  String? id;
  String? name;
  PacketData? data;

  bool? failed;
  bool? sending;
  bool? cancelled;
  bool? noForwarding;

  Packet(this.name, this.data, this.id) {
    failed = false;
    sending = false;
  }

  Map<String, dynamic> toMap() {
    return data?.toMap() ?? {};
  }
}
