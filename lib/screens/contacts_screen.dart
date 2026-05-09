import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _service = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat Cifrado', style: TextStyle(color: Colors.white, fontSize: 18)),
            Text(
              _service.username ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar lista',
            onPressed: () {
              _service.requestUsersRefresh();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Actualizando lista de contactos...'),
                  duration: Duration(milliseconds: 800),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesion',
            onPressed: () {
              _service.disconnect();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: _service.usersStream,
        initialData: _service.currentUsers,
        builder: (context, usersSnapshot) {
          final users = usersSnapshot.data ?? [];
          return StreamBuilder<Map<String, int>>(
            stream: _service.unreadStream,
            initialData: _service.unreadCounts,
            builder: (context, unreadSnapshot) {
              final unread = unreadSnapshot.data ?? {};
              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text(
                        'Esperando que otros se conecten...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) {
                  final user = users[i];
                  final count = unread[user] ?? 0;
                  return ListTile(
                    onTap: () async {
                      _service.clearUnread(user);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(contactName: user),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: _avatarColor(user),
                      child: Text(
                        user[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'online',
                      style: TextStyle(color: Color(0xFF25D366), fontSize: 12),
                    ),
                    trailing: count > 0
                        ? CircleAvatar(
                            radius: 11,
                            backgroundColor: const Color(0xFF25D366),
                            child: Text(
                              '$count',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          )
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF1976D2),
      const Color(0xFF388E3C),
      const Color(0xFFD32F2F),
      const Color(0xFF7B1FA2),
      const Color(0xFFF57C00),
      const Color(0xFF0097A7),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
