import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  IO.Socket? get socket => _socket;
  bool get isConnected => _isConnected;

  void connect({required String token, required String userName}) {
    if (_socket != null) {
      debugPrint('🔌 SocketService: Socket already exists, disconnecting first...');
      _socket!.disconnect();
      _socket = null;
    }

    final String url = ApiConfig.socketUrl;
    debugPrint('🔌 SocketService: Initializing WebSocket connection to $url...');

    try {
      _socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({
              'token': token,
              'userName': userName,
            })
            .enableAutoConnect()
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(5)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('✅ SocketService: WebSocket Connected!');
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        debugPrint('❌ SocketService: WebSocket Disconnected');
        _isConnected = false;
      });

      _socket!.onConnectError((err) {
        debugPrint('SocketService connection error: $err');
      });
      
      _socket!.connect();
    } catch (e) {
      debugPrint('Failed to initialize socket: $e');
    }
  }

  void disconnect() {
    if (_socket != null) {
      debugPrint('🔌 SocketService: Disconnecting socket...');
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }
}
