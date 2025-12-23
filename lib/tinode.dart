library tindarts_sdk;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';
import 'package:get_it/get_it.dart';

import 'package:tindarts_sdk/src/models/topic-names.dart' as topic_names;
import 'package:tindarts_sdk/src/models/server-configuration.dart';
import 'package:tindarts_sdk/src/models/connection-options.dart';
import 'package:tindarts_sdk/src/services/packet-generator.dart';
import 'package:tindarts_sdk/src/services/future-manager.dart';
import 'package:tindarts_sdk/src/models/server-messages.dart';
import 'package:tindarts_sdk/src/services/cache-manager.dart';
import 'package:tindarts_sdk/src/services/configuration.dart';
import 'package:tindarts_sdk/src/models/account-params.dart';
import 'package:tindarts_sdk/src/services/connection.dart';
import 'package:tindarts_sdk/src/models/access-mode.dart';
import 'package:tindarts_sdk/src/models/set-params.dart';
import 'package:tindarts_sdk/src/models/auth-token.dart';
import 'package:tindarts_sdk/src/models/del-range.dart';
import 'package:tindarts_sdk/src/models/get-query.dart';
import 'package:tindarts_sdk/src/services/logger.dart';
import 'package:tindarts_sdk/src/services/tinode.dart';
import 'package:tindarts_sdk/src/models/message.dart';
import 'package:tindarts_sdk/src/services/tools.dart';
import 'package:tindarts_sdk/src/services/auth.dart';
import 'package:tindarts_sdk/src/services/file_service.dart';
import 'package:tindarts_sdk/src/topic-fnd.dart';
import 'package:tindarts_sdk/src/topic-me.dart';
import 'package:tindarts_sdk/src/topic.dart';

export 'package:tindarts_sdk/src/models/server-configuration.dart';
export 'package:tindarts_sdk/src/models/connection-options.dart';
export 'package:tindarts_sdk/src/models/delete-transaction.dart';
export 'package:tindarts_sdk/src/models/topic-subscription.dart';
export 'package:tindarts_sdk/src/models/topic-description.dart';
export 'package:tindarts_sdk/src/models/server-messages.dart';
export 'package:tindarts_sdk/src/models/account-params.dart';
export 'package:tindarts_sdk/src/models/message-status.dart';
export 'package:tindarts_sdk/src/models/contact-update.dart';
export 'package:tindarts_sdk/src/models/app-settings.dart';
export 'package:tindarts_sdk/src/models/packet-types.dart';
export 'package:tindarts_sdk/src/models/packet-data.dart';
export 'package:tindarts_sdk/src/models/auth-token.dart';
export 'package:tindarts_sdk/src/models/credential.dart';
export 'package:tindarts_sdk/src/models/set-params.dart';
export 'package:tindarts_sdk/src/meta-get-builder.dart';
export 'package:tindarts_sdk/src/models/del-range.dart';
export 'package:tindarts_sdk/src/models/get-query.dart';
export 'package:tindarts_sdk/src/services/tools.dart';
export 'package:tindarts_sdk/src/services/file_service.dart';
export 'package:tindarts_sdk/src/services/connection.dart' show ConnectionState;
export 'package:tindarts_sdk/src/models/def-acs.dart';
export 'package:tindarts_sdk/src/sorted-cache.dart';
export 'package:tindarts_sdk/src/topic-fnd.dart';
export 'package:tindarts_sdk/src/topic-me.dart';
export 'package:tindarts_sdk/src/topic.dart';

/// Provides a simple interface to interact with tinode server using websocket
class Tinode {
  /// Authentication service, responsible for managing credentials and user id
  late AuthService _authService;

  /// Cache manager service, responsible for read and write operations on cached data
  late CacheManager _cacheManager;

  /// Configuration service, responsible for storing library config and information
  late ConfigService _configService;

  /// Tinode service, responsible for handling messages, preparing packets and sending them
  late TinodeService _tinodeService;

  /// Future manager, responsible for making futures and executing them
  late FutureManager _futureManager;

  /// Logger service, responsible for logging content in different levels
  late LoggerService _loggerService;

  /// Connection service, responsible for establishing a websocket connection to the server
  late ConnectionService _connectionService;

  /// File service for uploads and downloads
  late FileService _fileService;

  /// `onMessage` subscription stored to unsubscribe later
  StreamSubscription<String>? _onMessageSubscription;

  /// `onConnected` subscription stored to unsubscribe later
  StreamSubscription<void>? _onConnectedSubscription;

  /// `onDisconnect` subscription stored to unsubscribe later
  StreamSubscription<void>? _onDisconnectedSubscription;

  /// `onConnected` event will be triggered when connection opens
  PublishSubject<void> onConnected = PublishSubject<void>();

  /// `onDisconnect` event will be triggered when connection is closed
  PublishSubject<void> onDisconnect = PublishSubject<void>();

  /// `onNetworkProbe` event will be triggered when network prob packet is received
  PublishSubject<void> onNetworkProbe = PublishSubject<void>();

  /// `onMessage` event will be triggered when a message is received
  PublishSubject<ServerMessage> onMessage = PublishSubject<ServerMessage>();

  /// `onRawMessage` event will be triggered when a message is received value will be a json
  PublishSubject<String> onRawMessage = PublishSubject<String>();

  /// Creates an instance of Tinode interface to interact with tinode server using websocket
  ///
  /// `appName` name of the client
  ///
  /// `options` connection configuration and api key
  ///
  /// `loggerEnabled` pass `true` if you want to turn the logger on
  Tinode(String appName, ConnectionOptions options, bool loggerEnabled) {
    _registerDependencies(options, loggerEnabled);
    _resolveDependencies();
    _fileService = FileService(options);

    _configService.appName = appName;
    _doSubscriptions();
  }

  /// Register services in dependency injection container
  void _registerDependencies(ConnectionOptions options, bool loggerEnabled) {
    var registered = GetIt.I.isRegistered<ConfigService>();

    if (!registered) {
      GetIt.I.registerSingleton<ConfigService>(ConfigService(loggerEnabled));
      GetIt.I.registerSingleton<LoggerService>(LoggerService());
      GetIt.I.registerSingleton<AuthService>(AuthService());
      GetIt.I.registerSingleton<ConnectionService>(ConnectionService(options));
      GetIt.I.registerSingleton<FutureManager>(FutureManager());
      GetIt.I.registerSingleton<PacketGenerator>(PacketGenerator());
      GetIt.I.registerSingleton<CacheManager>(CacheManager());
      GetIt.I.registerSingleton<TinodeService>(TinodeService());
    }
  }

  /// Resolve dependencies from container
  void _resolveDependencies() {
    _configService = GetIt.I.get<ConfigService>();
    _tinodeService = GetIt.I.get<TinodeService>();
    _futureManager = GetIt.I.get<FutureManager>();
    _loggerService = GetIt.I.get<LoggerService>();
    _connectionService = GetIt.I.get<ConnectionService>();
    _cacheManager = GetIt.I.get<CacheManager>();
    _authService = GetIt.I.get<AuthService>();
  }

  /// Subscribe to needed events like connection
  void _doSubscriptions() {
    _onMessageSubscription ??= _connectionService.onMessage.listen((input) {
      _onConnectionMessage(input);
    });

    _onConnectedSubscription ??= _connectionService.onOpen.listen((_) {
      _futureManager.checkExpiredFutures();
      onConnected.add(null);
    });

    _onDisconnectedSubscription ??= _connectionService.onDisconnect.listen((_) {
      _onConnectionDisconnect();
    });

    _futureManager.startCheckingExpiredFutures();
  }

  /// Unsubscribe every subscription to prevent memory leak
  void _unsubscribeAll() {
    _onMessageSubscription?.cancel();
    _onConnectedSubscription?.cancel();
    _futureManager.stopCheckingExpiredFutures();
  }

  /// Unsubscribe and reset local variables when connection closes
  void _onConnectionDisconnect() {
    _unsubscribeAll();
    _futureManager.rejectAllFutures(0, 'disconnect');
    _cacheManager.map((String key, dynamic value) {
      if (key.contains('topic:')) {
        Topic topic = value as Topic;
        topic.resetSubscription();
      }
      return MapEntry(key, value);
    });
    onDisconnect.add(null);
  }

  /// Handler for newly received messages from server
  void _onConnectionMessage(String? input) {
    if (input == null || input == '') {
      return;
    }
    _loggerService.log('in: ' + input);

    // Send raw message to listener
    onRawMessage.add(input);

    if (input == '0') {
      onNetworkProbe.add(null);
      return;
    }

    var pkt = jsonDecode(input, reviver: Tools.jsonParserHelper);
    if (pkt == null) {
      _loggerService.error('failed to parse data');
      return;
    }

    /// Decode map into model
    var message = ServerMessage.fromMessage(pkt as Map<String, dynamic>);

    // Send complete packet to listener
    onMessage.add(message);

    if (message.ctrl != null) {
      _tinodeService.handleCtrlMessage(message.ctrl);
    } else if (message.meta != null) {
      _tinodeService.handleMetaMessage(message.meta);
    } else if (message.data != null) {
      _tinodeService.handleDataMessage(message.data);
    } else if (message.pres != null) {
      _tinodeService.handlePresMessage(message.pres);
    } else if (message.info != null) {
      _tinodeService.handleInfoMessage(message.info);
    }
  }

  // Get app version
  String get version {
    return _configService.appVersion;
  }

  /// Open the connection and send a hello packet to server
  Future<dynamic> connect() async {
    _doSubscriptions();
    await _connectionService.connect();
    return hello();
  }

  /// Close the current connection
  void disconnect() {
    _connectionService.disconnect();
  }

  /// Send a network probe message to make sure the connection is alive
  void networkProbe() {
    _connectionService.probe();
  }

  /// Is current connection open
  bool get isConnected {
    return _connectionService.isConnected;
  }

  /// Specifies if user is authenticated
  bool get isAuthenticated {
    return _authService.isAuthenticated;
  }

  /// Current user token
  AuthToken? get token {
    return _authService.authToken;
  }

  /// Current user id
  String get userId {
    return _authService.userId!;
  }

  /// Say hello and set some initial configuration like:
  /// * User agent
  /// * Device token for notifications
  /// * Language
  /// * Platform
  Future<CtrlMessage> hello({String? deviceToken}) async {
    var response = await _tinodeService.hello(deviceToken: deviceToken);
    CtrlMessage ctrl = response is CtrlMessage ? response : CtrlMessage.fromMessage(response as Map<String, dynamic>);

    if (ctrl.params != null) {
      _configService.setServerConfiguration(ctrl.params as Map<String, dynamic>);
    }
    return ctrl;
  }

  /// Wrapper for `hello`, sends hi packet again containing device token
  Future<CtrlMessage> setDeviceToken(String deviceToken) {
    return hello(deviceToken: deviceToken);
  }

  /// Create or update an account
  ///
  /// * Scheme can be `basic` or `token` or `reset`
  Future<dynamic> account(String userId, String scheme, String secret, bool login, AccountParams? params) {
    return _tinodeService.account(userId, scheme, secret, login, params);
  }

  /// Create a new user. Wrapper for `account` method
  Future<dynamic> createAccount(String scheme, String secret, bool login, AccountParams? params) {
    var promise = account(topic_names.USER_NEW, scheme, secret, login, params);
    if (login) {
      promise = promise.then((dynamic ctrl) {
        _authService.onLoginSuccessful(ctrl as CtrlMessage);
        return ctrl;
      });
    }
    return promise;
  }

  /// Create user with 'basic' authentication scheme and immediately
  /// use it for authentication. Wrapper for `createAccount`
  Future<dynamic> createAccountBasic(String username, String password, bool login, AccountParams? params) {
    var secret = base64.encode(utf8.encode(username + ':' + password));
    return createAccount('basic', secret, login, params);
  }

  /// Update account with basic
  Future<dynamic> updateAccountBasic(String userId, String username, String password, AccountParams? params) {
    var secret = base64.encode(utf8.encode(username + ':' + password));
    return account(userId, 'basic', secret, false, params);
  }

  /// Authenticate current session
  Future<CtrlMessage> login(String scheme, String secret, Map<String, dynamic>? cred) {
    return _tinodeService.login(scheme, secret, cred);
  }

  /// Wrapper for `login` with basic authentication
  Future<CtrlMessage> loginBasic(String username, String password, Map<String, dynamic>? cred) async {
    var secret = base64.encode(utf8.encode(username + ':' + password));
    var ctrl = await login('basic', secret, cred);
    _authService.setLastLogin(username);
    return ctrl;
  }

  /// Wrapper for `login` with token authentication
  Future<CtrlMessage> loginToken(String token, Map<String, dynamic> cred) {
    return login('token', token, cred);
  }

  /// Send a request for resetting an authentication secret
  /// * scheme - authentication scheme to reset ex: `basic`
  /// * method - method to use for resetting the secret, such as "email" or "tel"
  /// * value - value of the credential to use, a specific email address or a phone number
  Future<CtrlMessage> requestResetSecret(String scheme, String method, String value) {
    var secret = base64.encode(utf8.encode(scheme + ':' + method + ':' + value));
    return login('reset', secret, null);
  }

  /// Get stored authentication token
  AuthToken? getAuthenticationToken() {
    return _authService.authToken;
  }

  /// Send a topic subscription request
  Future<dynamic> subscribe(String topicName, GetQuery getParams, SetParams setParams) {
    return _tinodeService.subscribe(topicName, getParams, setParams);
  }

  /// Detach and optionally unsubscribe from the topic
  Future<dynamic> leave(String topicName, bool unsubscribe) {
    return _tinodeService.leave(topicName, unsubscribe);
  }

  /// Create message draft without sending it to the server
  Message createMessage(String topicName, dynamic data, bool echo) {
    return _tinodeService.createMessage(topicName, data, echo);
  }

  /// Publish message to topic. The message should be created by `createMessage`
  Future<dynamic> publishMessage(Message message) {
    return _tinodeService.publishMessage(message);
  }

  /// Request topic metadata
  Future<dynamic> getMeta(String topicName, GetQuery params) {
    return _tinodeService.getMeta(topicName, params);
  }

  /// Update topic's metadata: description, subscriptions
  Future<dynamic> setMeta(String topicName, SetParams params) {
    return _tinodeService.setMeta(topicName, params);
  }

  /// Delete some or all messages in a topic
  Future<dynamic> deleteMessages(String topicName, List<DelRange> ranges, bool hard) {
    return _tinodeService.deleteMessages(topicName, ranges, hard);
  }

  /// Delete the topic all together. Requires Owner permission
  Future<dynamic> deleteTopic(String topicName, bool hard) {
    return _tinodeService.deleteTopic(topicName, hard);
  }

  /// Delete subscription. Requires Share permission
  Future<dynamic> deleteSubscription(String topicName, String userId) {
    return _tinodeService.deleteSubscription(topicName, userId);
  }

  /// Delete credential. Always sent on 'me' topic
  Future<dynamic> deleteCredential(String method, String value) {
    return _tinodeService.deleteCredential(method, userId);
  }

  /// Request to delete account of the current user
  Future<dynamic> deleteCurrentUser(bool hard) async {
    var ctrl = _tinodeService.deleteCurrentUser(hard);
    _authService.setUserId(null);
    return ctrl;
  }

  /// Notify server that a message or messages were read or received.
  ///
  /// [topicName] - The topic to send the notification to
  /// [what] - Notification type: 'recv' or 'read'
  /// [seq] - Message sequence ID
  /// [unread] - Optional total count of unread messages
  void note(String topicName, String what, int seq, {int? unread}) {
    _tinodeService.note(topicName, what, seq, unread: unread);
  }

  /// Broadcast a key-press notification to topic subscribers.
  ///
  /// Used to show typing notifications "user X is typing..."
  ///
  /// [topicName] - The topic to send the notification to
  /// [audioRecording] - Set to true for audio recording notification
  /// [videoRecording] - Set to true for video recording notification
  Future<void> noteKeyPress(
    String topicName, {
    bool audioRecording = false,
    bool videoRecording = false,
  }) async {
    await _tinodeService.noteKeyPress(
      topicName,
      audioRecording: audioRecording,
      videoRecording: videoRecording,
    );
  }

  /// Send a video call notification.
  ///
  /// Used for WebRTC call signaling through the Tinode server.
  ///
  /// [topicName] - The topic (usually P2P) to send the call notification to
  /// [seq] - Message sequence ID of the call message
  /// [event] - Call event type from [VideoCallEvent]: 'invite', 'ringing',
  ///           'accept', 'answer', 'offer', 'ice-candidate', 'hang-up'
  /// [payload] - Optional payload data (SDP for offer/answer, ICE candidate data)
  Future<void> noteCall(
    String topicName,
    int seq,
    String event, {
    Map<String, dynamic>? payload,
  }) async {
    await _tinodeService.noteCall(topicName, seq, event, payload: payload);
  }

  /// Send generic data notification.
  ///
  /// [topicName] - The topic to send the notification to
  /// [payload] - Data payload to send
  Future<void> noteData(String topicName, Map<String, dynamic> payload) async {
    await _tinodeService.noteData(topicName, payload);
  }

  /// Get a named topic, either pull it from cache or create a new instance
  /// There is a single instance of topic for each name
  Topic getTopic(String topicName) {
    return _tinodeService.getTopic(topicName)!;
  }

  /// Check if named topic is already present in cache
  bool isTopicCached(String topicName) {
    final topic = _cacheManager.get('topic', topicName);
    return topic != null;
  }

  /// Instantiate a new group topic. An actual name will be assigned by the server
  Topic newTopic() {
    return _tinodeService.newTopic();
  }

  /// Instantiate a new channel-enabled group topic. An actual name will be assigned by the server
  Topic newChannel() {
    return _tinodeService.newTopic();
  }

  /// Generate unique name like 'new123456' suitable for creating a new group topic
  String newGroupTopicName(bool isChan) {
    return _tinodeService.newGroupTopicName(isChan);
  }

  /// Instantiate a new P2P topic with a given peer
  Topic newTopicWith(String peerUserId) {
    return _tinodeService.newTopicWith(peerUserId);
  }

  /// Instantiate 'me' topic or get it from cache
  TopicMe getMeTopic() {
    return _tinodeService.getTopic(topic_names.TOPIC_ME) as TopicMe;
  }

  /// Instantiate 'fnd' (find) topic or get it from cache
  TopicFnd getFndTopic() {
    return _tinodeService.getTopic(topic_names.TOPIC_FND) as TopicFnd;
  }

  /// Get the user id of the the current authenticated user
  String getCurrentUserId() {
    return _authService.userId!;
  }

  /// Check if the given user ID is equal to the current user's user id
  bool isMe(String userId) {
    return _tinodeService.isMe(userId);
  }

  /// Get login (user id) used for last successful authentication.
  String getCurrentLogin() {
    return _authService.lastLogin!;
  }

  /// Return information about the server: protocol, version, limits, and build timestamp
  ServerConfiguration getServerInfo() {
    return _configService.serverConfiguration;
  }

  /// Enable or disable logger service
  void enableLogger(bool enabled) {
    _configService.loggerEnabled = enabled;
  }

  /// Set UI language to report to the server. Must be called before 'hi' is sent, otherwise it will not be used
  void setHumanLanguage(String language) {
    _configService.humanLanguage = language;
  }

  /// Check if given topic is online
  bool isTopicOnline(String topicName) {
    var me = getMeTopic();
    var cont = me.getContact(topicName);
    return cont != null && cont.online!;
  }

  /// Get access mode for the given contact
  AccessMode? getTopicAccessMode(String topicName) {
    var me = getMeTopic();
    var cont = me.getContact(topicName);
    return cont != null ? cont.acs : null;
  }

  // ============== File Upload/Download API ==============

  /// Get the file service for advanced file operations.
  ///
  /// The file service provides streams for monitoring upload/download progress:
  /// - [FileService.onUploadProgress] - Stream of upload progress updates
  /// - [FileService.onDownloadProgress] - Stream of download progress updates
  FileService get fileService => _fileService;

  /// Upload a file to the server.
  ///
  /// [fileBytes] - The file content as bytes
  /// [filename] - The name of the file
  /// [mimeType] - The MIME type of the file (e.g., 'image/jpeg', 'application/pdf')
  /// [onProgress] - Optional callback for progress updates
  ///
  /// Returns an [UploadResult] containing the URL of the uploaded file.
  ///
  /// Example:
  /// ```dart
  /// final result = await tinode.uploadFile(
  ///   fileBytes: imageBytes,
  ///   filename: 'photo.jpg',
  ///   mimeType: 'image/jpeg',
  ///   onProgress: (progress) {
  ///     print('Upload: ${progress.percentage}%');
  ///   },
  /// );
  /// print('Uploaded to: ${result.fullUrl}');
  /// ```
  Future<UploadResult> uploadFile({
    required Uint8List fileBytes,
    required String filename,
    required String mimeType,
    void Function(FileProgress)? onProgress,
  }) {
    return _fileService.uploadFile(
      fileBytes: fileBytes,
      filename: filename,
      mimeType: mimeType,
      onProgress: onProgress,
    );
  }

  /// Download a file from the server.
  ///
  /// [url] - The file URL (can be relative or absolute)
  /// [onProgress] - Optional callback for progress updates
  ///
  /// Returns the file content as bytes.
  ///
  /// Example:
  /// ```dart
  /// final bytes = await tinode.downloadFile(
  ///   url: '/v0/file/s/abc123',
  ///   onProgress: (progress) {
  ///     if (progress.percentage >= 0) {
  ///       print('Download: ${progress.percentage}%');
  ///     }
  ///   },
  /// );
  /// ```
  Future<Uint8List> downloadFile({
    required String url,
    void Function(FileProgress)? onProgress,
  }) {
    return _fileService.downloadFile(
      url: url,
      onProgress: onProgress,
    );
  }

  // ============== Connection State API ==============

  /// Get the current connection state
  ConnectionState get connectionState => _connectionService.connectionState;

  /// Stream of connection state changes for monitoring connection status.
  ///
  /// Use this to update UI or trigger reconnection logic.
  ///
  /// Example:
  /// ```dart
  /// tinode.onConnectionStateChange.listen((state) {
  ///   switch (state) {
  ///     case ConnectionState.connected:
  ///       print('Connected!');
  ///       break;
  ///     case ConnectionState.disconnected:
  ///       print('Disconnected');
  ///       break;
  ///     case ConnectionState.reconnecting:
  ///       print('Attempting to reconnect...');
  ///       break;
  ///     case ConnectionState.connecting:
  ///       print('Connecting...');
  ///       break;
  ///   }
  /// });
  /// ```
  Stream<ConnectionState> get onConnectionStateChange =>
      _connectionService.onConnectionStateChange.stream;

  /// Enable or disable auto-reconnect.
  ///
  /// When enabled, the SDK will automatically attempt to reconnect
  /// using exponential backoff when the connection is lost.
  set autoReconnect(bool value) => _connectionService.autoReconnect = value;
  bool get autoReconnect => _connectionService.autoReconnect;

  /// Set maximum reconnection attempts (0 = unlimited).
  set maxReconnectAttempts(int value) =>
      _connectionService.maxReconnectAttempts = value;
  int get maxReconnectAttempts => _connectionService.maxReconnectAttempts;

  /// Set base delay for exponential backoff (in milliseconds).
  set baseReconnectDelay(int value) =>
      _connectionService.baseReconnectDelay = value;
  int get baseReconnectDelay => _connectionService.baseReconnectDelay;

  /// Set maximum delay between reconnection attempts (in milliseconds).
  set maxReconnectDelay(int value) =>
      _connectionService.maxReconnectDelay = value;
  int get maxReconnectDelay => _connectionService.maxReconnectDelay;

  /// Force a reconnection (disconnect and immediately reconnect).
  Future<void> reconnect() => _connectionService.reconnect();

  /// Check if currently connecting or reconnecting.
  bool get isConnecting => _connectionService.isConnecting;
}
