import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  WebSocketChannel? _channel;
  String? username;
  String? serverIp;

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

  void connect(String ip, String name) {
    username = name;
    serverIp = ip;
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://$ip:8000/chat/$name'),
    );
    _channel!.stream.listen(
      (data) {
        final msg = jsonDecode(data as String) as Map<String, dynamic>;

        if (msg['tipo'] == 'ping') {
          // Heartbeat: el servidor pregunta si seguimos vivos -> respondemos pong
          _channel?.sink.add(jsonEncode({'tipo': 'pong'}));

        } else if (msg['tipo'] == 'usuarios') {
          // Lista de usuarios actualizada por el servidor
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
      onError: (e) => _messageController.add({'tipo': 'error', 'texto': e.toString()}),
    );
  }

  void send(String to, String text) {
    _channel?.sink.add(jsonEncode({'para': to, 'texto': text}));
  }

  /// Pide al servidor la lista actualizada de usuarios conectados.
  /// Lo usa el boton de refresh manual.
  void requestUsersRefresh() {
    _channel?.sink.add(jsonEncode({'tipo': 'get_users'}));
  }

  void clearUnread(String contact) {
    unreadCounts[contact] = 0;
    _unreadController.add(Map.from(unreadCounts));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    username = null;
    serverIp = null;
    unreadCounts.clear();
    currentUsers = [];
  }
}
