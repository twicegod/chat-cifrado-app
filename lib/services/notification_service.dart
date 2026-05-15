import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones locales del dispositivo.
///
/// Cuando llega un mensaje y la app esta en background o cerrada,
/// dispara una notificacion en la barra de notificaciones del celular.
///
/// En Flutter Web no hace nada (las APIs no aplican).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'chat_cifrado_msgs';
  static const String _channelName = 'Mensajes del chat';
  static const String _channelDesc = 'Avisos cuando llega un mensaje nuevo';

  /// Inicializa el plugin y pide permisos. Llamar una vez al arrancar la app.
  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings);

    // Crear canal de notificaciones (necesario en Android 8+)
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Pedir permiso de notificaciones (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Dispara una notificacion de mensaje recibido.
  Future<void> showMessage({
    required String from,
    required String text,
  }) async {
    if (kIsWeb || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Nuevo mensaje',
    );

    final details = const NotificationDetails(android: androidDetails);

    // Usamos el hash del nombre como ID para que mensajes del mismo
    // contacto se agrupen visualmente y no inunden la barra.
    final id = from.hashCode & 0x7FFFFFFF;

    await _plugin.show(id, from, text, details);
  }

  /// Cancela todas las notificaciones (al hacer logout).
  Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }
}
