import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  WebSocketChannel? _channel;
  String? username;
  String? serverIp;

  // Auto-reconexion
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _intentionalDisconnect = false; // true cuando el usuario hace logout
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Stream del estado de conexion (lo escucha el AppBar para mostrar indicador)
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _statusController.stream;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  // Lista de usuarios en tiempo real via WebSocket
  final _usersController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get usersStream => _usersController.stream;
  List<String> currentUsers = [];

  // Contador de no leídos
  final Map<String, int> unreadCounts = {};
  final _unreadController = StreamController<Map<String, int>>.broadcast();
  Stream<Map<String, int>> get unreadStream => _unreadController.stream;

  /// Conexion inicial (llamada desde la pantalla de login).
  void connect(String ip, String name) {
    username = name;
    serverIp = ip;
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    _doConnect();
  }

  /// Conexion real al WebSocket. Se llama tanto en la primera conexion
  /// como en cada reintento.
  void _doConnect() {
    if (serverIp == null || username == null) return;
    if (_intentionalDisconnect) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$serverIp:8000/chat/$username'),
      );

      _channel!.stream.listen(
        (data) {
          // Si llego algo, estamos conectados (por las dudas)
          if (!_isConnected) {
            _isConnected = true;
            _statusController.add(true);
            _reconnectAttempts = 0;
          }

          final msg = jsonDecode(data as String) as Map<String, dynamic>;

          if (msg['tipo'] == 'ping') {
            _channel?.sink.add(jsonEncode({'tipo': 'pong'}));

          } else if (msg['tipo'] == 'usuarios') {
            final lista = List<String>.from(msg['lista'] as List);
            currentUsers = lista.where((u) => u != username).toList();
            _usersController.add(currentUsers);

          } else if (msg['tipo'] == 'mensaje') {
            final from = msg['de'] as String;
            unreadCounts[from] = (unreadCounts[from] ?? 0) + 1;
            _unreadController.add(Map.from(unreadCounts));
            _messageController.add(msg);

          } else {
            _messageController.add(msg);
          }
        },
        onError: (e) {
          _handleDisconnection();
        },
        onDone: () {
          _handleDisconnection();
        },
        cancelOnError: true,
      );

      _isConnected = true;
      _statusController.add(true);
      _reconnectAttempts = 0;

    } catch (e) {
      _handleDisconnection();
    }
  }

  /// Se llama cuando el WebSocket se cae. Programa un reintento.
  void _handleDisconnection() {
    _isConnected = false;
    _statusController.add(false);

    if (_intentionalDisconnect) return;

    // Backoff exponencial: 2, 4, 8, 16, 30, 30, 30...
    _reconnectAttempts++;
    final delaySegs = min(pow(2, _reconnectAttempts).toInt(), 30);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySegs), _doConnect);
  }

  /// Fuerza reconexion inmediata (lo usa el observer de ciclo de vida
  /// cuando el celular despierta).
  void forceReconnect() {
    if (_intentionalDisconnect) return;
    if (_isConnected) return; // ya conectados, no hace falta

    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _doConnect();
  }

  void send(String to, String text) {
    _channel?.sink.add(jsonEncode({'para': to, 'texto': text}));
  }

  /// Pide al servidor la lista actualizada de usuarios conectados.
  void requestUsersRefresh() {
    _channel?.sink.add(jsonEncode({'tipo': 'get_users'}));
  }

  void clearUnread(String contact) {
    unreadCounts[contact] = 0;
    _unreadController.add(Map.from(unreadCounts));
  }

  /// Desconexion intencional (logout). Cancela los reintentos.
  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _statusController.add(false);
    username = null;
    serverIp = null;
    unreadCounts.clear();
    currentUsers = [];
  }
}
