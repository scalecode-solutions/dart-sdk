import 'package:get_it/get_it.dart';

import 'package:tindarts_sdk/src/models/packet_types.dart' as packet_types;
import 'package:tindarts_sdk/src/services/configuration.dart';
import 'package:tindarts_sdk/src/models/packet_data.dart';
import 'package:tindarts_sdk/src/services/tools.dart';
import 'package:tindarts_sdk/src/models/packet.dart';

class PacketGenerator {
  late ConfigService _configService;

  PacketGenerator() {
    _configService = GetIt.I.get<ConfigService>();
  }

  Packet generate(String type, String? topicName) {
    PacketData packetData;
    switch (type) {
      case packet_types.hi:
        packetData = HiPacketData(
          ver: _configService.appVersion,
          ua: _configService.userAgent,
          dev: _configService.deviceToken,
          lang: _configService.humanLanguage,
          platf: _configService.platform,
        );
        break;

      case packet_types.acc:
        packetData = AccPacketData(
          user: null,
          scheme: null,
          secret: null,
          login: false,
          tags: null,
          desc: null,
          cred: null,
          token: null,
        );
        break;

      case packet_types.login:
        packetData = LoginPacketData(
          scheme: null,
          secret: null,
          cred: null,
        );
        break;

      case packet_types.sub:
        packetData = SubPacketData(
          topic: topicName,
          set: null,
          get: null,
        );
        break;

      case packet_types.leave:
        packetData = LeavePacketData(
          topic: topicName,
          unsub: false,
        );
        break;

      case packet_types.pub:
        packetData = PubPacketData(
          topic: topicName,
          noecho: false,
          content: null,
          head: null,
          from: null,
          seq: null,
          ts: null,
        );
        break;

      case packet_types.get:
        packetData = GetPacketData(
          topic: topicName,
          what: null,
          desc: null,
          sub: null,
          data: null,
        );
        break;

      case packet_types.set:
        packetData = SetPacketData(
          topic: topicName,
          desc: null,
          sub: null,
          tags: null,
        );
        break;

      case packet_types.del:
        packetData = DelPacketData(
          topic: topicName,
          what: null,
          delseq: null,
          hard: false,
          user: null,
          cred: null,
        );
        break;

      case packet_types.note:
        packetData = NotePacketData(
          topic: topicName,
          seq: null,
          what: null,
        );
        break;
      default:
        throw Exception('Unknown packet type: $type');
    }

    return Packet(type, packetData, Tools.getNextUniqueId());
  }
}
