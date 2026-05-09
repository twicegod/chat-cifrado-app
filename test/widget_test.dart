// Test basico de la app de chat cifrado.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chat_cifrado_app/main.dart';

void main() {
  testWidgets('La app arranca y muestra la pantalla de login', (WidgetTester tester) async {
    await tester.pumpWidget(const ChatApp());
    await tester.pump();

    // La pantalla de login muestra el titulo "Chat Cifrado"
    expect(find.text('Chat Cifrado'), findsOneWidget);
    // Y un boton CONECTAR
    expect(find.text('CONECTAR'), findsOneWidget);
  });
}
