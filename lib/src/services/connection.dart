import 'dart:async';
import 'dart:math';

import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';

import 'package:tindarts_sdk/src/models/connection_options.dart';
import 'package:tindarts_sdk/src/services/logger.dart';
import 'package:tindarts_sdk/src/services/tools.dart';

import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/io.dart';

/// Connection state enumeration
enum ConnectionState {
  /// Not connected and not trying to connect
  disconnected,

  /// Currently attempting to connect
  connecting,

  /// Successfully connected
  connected,

  /// Waiting before reconnection attempt
  reconnecting,
}

/// This class is responsible for `ws` connection establishments
///
/// Supports `ws` and `wss` with automatic reconnection using exponential backoff.
class ConnectionService {
  /// Connection configuration options provided by library user
  final ConnectionOptions _options;

  /// Websocket wrapper channel based on `dart:io`
  IOWebSocketChannel? _channel;

  /// Websocket connection
  WebSocket? _ws;

  /// Current connection state
  ConnectionState _connectionState = ConnectionState.disconnected;

  /// This callback will be called when connection is opened
  PublishSubject<dynamic> onOpen = PublishSubject<dynamic>();

  /// This callback will be called when connection is closed
  PublishSubject<void> onDisconnect = PublishSubject<void>();

  /// This callback will be called when we receive a message from server
  PublishSubject<String> onMessage = PublishSubject<String>();

  /// Stream of connection state changes
  final PublishSubject<ConnectionState> onConnectionStateChange =
      PublishSubject<ConnectionState>();

  late LoggerService _loggerService;

  /// Whether auto-reconnect is enabled
  bool autoReconnect = true;

  /// Whether we're intentionally disconnecting (prevents auto-reconnect)
  bool _intentionalDisconnect = false;

  /// Current reconnection attempt number
  int _reconnectAttempt = 0;

  /// Maximum reconnection attempts (0 = unlimited)
  int maxReconnectAttempts = 0;

  /// Base delay for exponential backoff (in milliseconds)
  int baseReconnectDelay = 1000;

  /// Maximum delay between reconnection attempts (in milliseconds)
  int maxReconnectDelay = 30000;

  /// Jitter factor for randomizing reconnect delays (0-1)
  double jitterFactor = 0.1;

  /// Timer for reconnection attempts
  Timer? _reconnectTimer;

  /// Stream subscription for WebSocket messages
  StreamSubscription<dynamic>? _messageSubscription;

  /// Connection options is required. Defining callbacks is not necessary
  ConnectionService(this._options) {
    _loggerService = GetIt.I.get<LoggerService>();
  }

  /// Get current connection state
  ConnectionState get connectionState => _connectionState;

  /// Check if currently connected
  bool get isConnected {
    return _ws != null &&
        _ws?.readyState == WebSocket.open &&
        _connectionState == ConnectionState.connected;
  }

  /// Check if currently connecting or reconnecting
  bool get isConnecting {
    return _connectionState == ConnectionState.connecting ||
        _connectionState == ConnectionState.reconnecting;
  }

  /// Update connection state and notify listeners
  void _setConnectionState(ConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      onConnectionStateChange.add(state);
      _loggerService.log('Connection state changed to: $state');
    }
  }

  /// Calculate delay for next reconnection attempt using exponential backoff with jitter
  int _calculateReconnectDelay() {
    // Exponential backoff: baseDelay * 2^attempt
    final exponentialDelay = baseReconnectDelay * pow(2, _reconnectAttempt);

    // Cap at maximum delay
    final cappedDelay = min(exponentialDelay.toInt(), maxReconnectDelay);

    // Add jitter to prevent thundering herd
    final jitter = (Random().nextDouble() * 2 - 1) * jitterFactor * cappedDelay;

    return (cappedDelay + jitter).round();
  }

  /// Start opening websocket connection
  Future<void> connect() async {
    if (isConnected) {
      _loggerService.warn('Already connected');
      return;
    }

    if (isConnecting) {
      _loggerService.warn('Already connecting...');
      return;
    }

    _cancelReconnectTimer();
    _intentionalDisconnect = false;
    _reconnectAttempt = 0;

    await _doConnect();
  }

  /// Internal connection method
  Future<void> _doConnect() async {
    _setConnectionState(ConnectionState.connecting);
    final url = Tools.makeBaseURL(_options);
    _loggerService.log('Connecting to $url');

    try {
      _ws = await WebSocket.connect(url)
          .timeout(const Duration(milliseconds: 5000));

      _loggerService.log('Connected.');
      _channel = IOWebSocketChannel(_ws!);
      _reconnectAttempt = 0;
      _setConnectionState(ConnectionState.connected);
      onOpen.add('Opened');

      // Listen for messages
      _messageSubscription?.cancel();
      _messageSubscription = _channel?.stream.listen(
        (message) {
          onMessage.add(message as String);
        },
        onError: (Object error) {
          _loggerService.error('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          _loggerService.log('WebSocket connection closed');
          _handleDisconnect();
        },
      );
    } on TimeoutException {
      _loggerService.error('Connection timeout');
      _setConnectionState(ConnectionState.disconnected);
      _scheduleReconnect();
    } on SocketException catch (e) {
      _loggerService.error('Socket error: ${e.message}');
      _setConnectionState(ConnectionState.disconnected);
      _scheduleReconnect();
    } catch (e) {
      _loggerService.error('Connection error: $e');
      _setConnectionState(ConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Handle disconnection (may trigger auto-reconnect)
  void _handleDisconnect() {
    final wasConnected = _connectionState == ConnectionState.connected;

    _messageSubscription?.cancel();
    _messageSubscription = null;
    _channel = null;
    _ws = null;

    if (wasConnected) {
      onDisconnect.add(null);
    }

    _setConnectionState(ConnectionState.disconnected);

    // Auto-reconnect if not intentional
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  /// Schedule a reconnection attempt
  void _scheduleReconnect() {
    if (!autoReconnect || _intentionalDisconnect) {
      return;
    }

    if (maxReconnectAttempts > 0 && _reconnectAttempt >= maxReconnectAttempts) {
      _loggerService.error(
          'Max reconnection attempts ($maxReconnectAttempts) reached');
      return;
    }

    final delay = _calculateReconnectDelay();
    _reconnectAttempt++;

    _loggerService.log(
        'Scheduling reconnection attempt $_reconnectAttempt in ${delay}ms');
    _setConnectionState(ConnectionState.reconnecting);

    _cancelReconnectTimer();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      _doConnect();
    });
  }

  /// Cancel any pending reconnection timer
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Send a message through websocket connection
  void sendText(String str) {
    if (!isConnected) {
      throw Exception('Tried sending data but you are not connected yet.');
    }
    _channel?.sink.add(str);
  }

  /// Close current websocket connection
  ///
  /// [reconnect] - If false, disables auto-reconnect for this disconnect
  void disconnect({bool reconnect = false}) {
    _intentionalDisconnect = !reconnect;
    _cancelReconnectTimer();

    _messageSubscription?.cancel();
    _messageSubscription = null;
    _channel = null;

    if (_ws != null) {
      _ws?.close(status.goingAway);
      _ws = null;
    }

    _setConnectionState(ConnectionState.disconnected);
    onDisconnect.add(null);
  }

  /// Force a reconnection (disconnect and reconnect)
  Future<void> reconnect() async {
    _intentionalDisconnect = false;
    _reconnectAttempt = 0;
    disconnect(reconnect: true);
    await _doConnect();
  }

  /// Send network probe to check if connection is indeed live
  void probe() {
    return sendText('1');
  }

  /// Clean up resources
  void dispose() {
    _intentionalDisconnect = true;
    _cancelReconnectTimer();
    _messageSubscription?.cancel();
    disconnect();

    onOpen.close();
    onDisconnect.close();
    onMessage.close();
    onConnectionStateChange.close();
  }
}
