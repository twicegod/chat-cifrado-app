import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'local_db_service.dart';
import 'notification_service.dart';
import 'prefs_service.dart';

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

  // Ciclo de vida de la app: lo seteamos desde main.dart
  bool _appInForeground = true;
  void setAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
  }

  // El usuario que esta activo en una chat screen. Sirve para no notificar
  // mensajes del contacto que ya esta mirando.
  String? activeChatContact;

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

  // Indicador "escribiendo": mapa de usuarios que estan tipeando y cuando
  // mandaron su ultimo evento. Se limpia automaticamente despues de 3.5s.
  final Map<String, DateTime> _typingUsers = {};
  final _typingController = StreamController<Map<String, DateTime>>.broadcast();
  Stream<Map<String, DateTime>> get typingStream => _typingController.stream;
  Map<String, DateTime> get typingUsers => Map.from(_typingUsers);
  DateTime? _lastTypingSent;

  /// Conexion inicial (llamada desde la pantalla de login).
  void connect(String ip, String name) {
    username = name;
    serverIp = ip;
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    // Inicializar la DB local en paralelo (no bloquea la conexion)
    LocalDbService().init();
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

          } else if (msg['tipo'] == 'escribiendo') {
            final from = msg['de'] as String;
            _typingUsers[from] = DateTime.now();
            _typingController.add(Map.from(_typingUsers));
            // Auto-limpiar despues de 3.5s si no llega un evento nuevo
            Timer(const Duration(milliseconds: 3500), () {
              final last = _typingUsers[from];
              if (last != null &&
                  DateTime.now().difference(last).inMilliseconds >= 3000) {
                _typingUsers.remove(from);
                _typingController.add(Map.from(_typingUsers));
              }
            });

          } else if (msg['tipo'] == 'historial') {
            // Sincronizamos el historial completo en la DB local
            final mensajes = (msg['mensajes'] as List?) ?? [];
            LocalDbService().syncHistorial(mensajes).then((_) {
              // Notificamos a las pantallas que el historial se actualizo
              _messageController.add({'tipo': 'historial_synced'});
            });

          } else if (msg['tipo'] == 'mensaje') {
            final from = msg['de'] as String;
            final texto = msg['texto'] as String;
            // Guardar en DB local
            LocalDbService().saveReceivedMessage(
              serverId: msg['id'] as int?,
              de: from,
              para: username ?? '',
              texto: texto,
            );
            unreadCounts[from] = (unreadCounts[from] ?? 0) + 1;
            _unreadController.add(Map.from(unreadCounts));
            _messageController.add(msg);

            // Notificacion local si:
            //   - la app NO esta en foreground, O
            //   - el usuario esta en otra pantalla / otro chat
            final viendoEstaConversacion =
                _appInForeground && activeChatContact == from;
            if (!viendoEstaConversacion) {
              NotificationService().showMessage(from: from, text: texto);
            }

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
    // Tambien lo guardamos en la DB local para que persista offline
    if (username != null) {
      LocalDbService().saveSentMessage(
        de: username!,
        para: to,
        texto: text,
      );
    }
  }

  /// Pide al servidor la lista actualizada de usuarios conectados.
  void requestUsersRefresh() {
    _channel?.sink.add(jsonEncode({'tipo': 'get_users'}));
  }

  /// Notifica al destinatario que estamos escribiendo.
  /// Throttle: envia como maximo un evento cada 2 segundos para no saturar.
  void sendTyping(String to) {
    final now = DateTime.now();
    if (_lastTypingSent != null &&
        now.difference(_lastTypingSent!).inSeconds < 2) {
      return;
    }
    _lastTypingSent = now;
    _channel?.sink.add(jsonEncode({'tipo': 'escribiendo', 'para': to}));
  }

  void clearUnread(String contact) {
    unreadCounts[contact] = 0;
    _unreadController.add(Map.from(unreadCounts));
  }

  /// Desconexion intencional (logout). Cancela los reintentos.
  /// Por defecto borra el cache local y el login guardado.
  Future<void> disconnect({bool clearCache = true}) async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _statusController.add(false);
    if (clearCache) {
      await LocalDbService().clearAll();
      await PrefsService.clearLogin();
    }
    await NotificationService().cancelAll();
    username = null;
    serverIp = null;
    unreadCounts.clear();
    currentUsers = [];
  }
}
