import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

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
