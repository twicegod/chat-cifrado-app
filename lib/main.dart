import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializar el sistema de notificaciones locales
    NotificationService().init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Informamos al servicio para que sepa si la app esta visible o no
    // (lo necesita para decidir si disparar notificaciones).
    ChatService().setAppLifecycleState(state);

    // Cuando la app vuelve a foreground forzamos reconexion
    if (state == AppLifecycleState.resumed) {
      ChatService().forceReconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Cifrado',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF075E54)),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
