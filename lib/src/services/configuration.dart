import 'dart:io' show Platform;

import 'package:tindarts_sdk/src/models/server_configuration.dart';
import 'package:tindarts_sdk/src/models/app_settings.dart';

class ConfigService {
  late ServerConfiguration _serverConfiguration;
  late AppSettings _appSettings;
  String? humanLanguage;
  String? deviceToken;
  bool? loggerEnabled;
  String appVersion = '';
  String appName = '';

  ConfigService(this.loggerEnabled) {
    _appSettings = AppSettings(0xFFFFFFF, 503, 1000, 5000);
    deviceToken = null;
    appVersion = '1.0.0-alpha.2';
    humanLanguage = 'en-US';
  }

  AppSettings get appSettings {
    return _appSettings;
  }

  ServerConfiguration get serverConfiguration {
    return _serverConfiguration;
  }

  String get userAgent {
    return '$appName (Dart; ${Platform.operatingSystem}); tinode-dart/$appVersion';
  }

  String get platform {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isFuchsia) {
      return 'Fuchsia';
    } else if (Platform.isIOS) {
      return 'IOS';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else if (Platform.isMacOS) {
      return 'MacOS';
    } else if (Platform.isWindows) {
      return 'Window';
    } else {
      return 'Unknown';
    }
  }

  void setServerConfiguration(Map<String, dynamic> configuration) {
    _serverConfiguration = ServerConfiguration(
      build: configuration['build'] as String?,
      maxFileUploadSize: configuration['maxFileUploadSize'] as int?,
      maxMessageSize: configuration['maxMessageSize'] as int?,
      maxSubscriberCount: configuration['maxSubscriberCount'] as int?,
      maxTagCount: configuration['maxTagCount'] as int?,
      maxTagLength: configuration['maxTagLength'] as int?,
      minTagLength: configuration['minTagLength'] as int?,
      ver: configuration['ver'] as String?,
    );
  }
}
