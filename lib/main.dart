import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/chat_service.dart';

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
    // Suscribirse a eventos del ciclo de vida (background, foreground, etc.)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Cuando la app vuelve a foreground (el usuario desbloquea el celular o
    // vuelve desde otra app), forzamos reconexion al servidor.
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
