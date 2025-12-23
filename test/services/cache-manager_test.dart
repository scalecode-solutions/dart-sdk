import 'package:get_it/get_it.dart';
import 'package:test/test.dart';

import 'package:tindarts_sdk/src/models/connection-options.dart';
import 'package:tindarts_sdk/src/models/topic-subscription.dart';
import 'package:tindarts_sdk/src/services/packet-generator.dart';
import 'package:tindarts_sdk/src/services/future-manager.dart';
import 'package:tindarts_sdk/src/services/cache-manager.dart';
import 'package:tindarts_sdk/src/services/configuration.dart';
import 'package:tindarts_sdk/src/services/connection.dart';
import 'package:tindarts_sdk/src/services/logger.dart';
import 'package:tindarts_sdk/src/services/tinode.dart';
import 'package:tindarts_sdk/src/services/auth.dart';
import 'package:tindarts_sdk/src/topic.dart';

void main() {
  GetIt.I.registerSingleton<ConfigService>(ConfigService(false));
  GetIt.I.registerSingleton<LoggerService>(LoggerService());
  GetIt.I.registerSingleton<AuthService>(AuthService());
  GetIt.I.registerSingleton<ConnectionService>(ConnectionService(ConnectionOptions('', '')));
  GetIt.I.registerSingleton<FutureManager>(FutureManager());
  GetIt.I.registerSingleton<PacketGenerator>(PacketGenerator());
  GetIt.I.registerSingleton<CacheManager>(CacheManager());
  GetIt.I.registerSingleton<TinodeService>(TinodeService());

  final service = CacheManager();

  test('put() should put data into cache', () {
    service.put('type', 'test', {'name': 'hello'});
    expect(service.get('type', 'test')['name'], 'hello');
  });

  test('putUser() should put user type data into cache', () {
    service.putUser('test', TopicSubscription(online: true));
    expect(service.get('user', 'test').online, true);
  });

  test('getUser() should return user type data from cache', () {
    service.putUser('test', TopicSubscription(online: true));
    expect(service.getUser('test')?.online, true);
  });

  test('deleteUser() should delete user type data from cache', () {
    service.putUser('test', TopicSubscription(online: true));
    expect(service.getUser('test')?.online, true);
    service.deleteUser('test');
    expect(service.getUser('test'), null);
  });

  test('putTopic() should put topic type data into cache', () {
    final t = Topic('cool');
    t.seq = 100;
    service.putTopic(t);
    expect(service.get('topic', 'cool').seq, 100);
  });

  test('deleteTopic() should delete topic type data from cache', () {
    final t = Topic('cool');
    t.seq = 100;
    service.putTopic(t);
    expect(service.get('topic', 'cool').seq, 100);
    service.deleteTopic('cool');
    expect(service.get('topic', 'cool'), null);
  });

  test('delete() should delete data from cache', () {
    service.put('type', 'test', {'name': 'hello'});
    expect(service.get('type', 'test')['name'], 'hello');
    service.delete('type', 'test');
    expect(service.get('type', 'test'), null);
  });

  test('map() should execute a function for all values in cache', () {
    final t = Topic('cool');
    t.isSubscribed = true;
    service.putTopic(t);
    service.map((String key, dynamic value) {
      if (key.contains('topic:')) {
        final Topic topic = value as Topic;
        topic.resetSubscription();
      }
      return MapEntry(key, value);
    });
    expect(service.get('topic', 'cool').isSubscribed, false);
  });
}
