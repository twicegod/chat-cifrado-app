import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/local_db_service.dart';

class ChatScreen extends StatefulWidget {
  final String contactName;
  const ChatScreen({super.key, required this.contactName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = ChatService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Message> _messages = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    // Marcamos esta conversacion como "activa" para que el service no dispare
    // notificaciones de mensajes de este contacto mientras la estamos viendo.
    _service.activeChatContact = widget.contactName;
    _loadHistorialLocal();
    _sub = _service.messages.listen((data) {
      if (data['tipo'] == 'mensaje' && data['de'] == widget.contactName) {
        setState(() {
          _messages.add(Message(
            from: data['de'] as String,
            text: data['texto'] as String,
            isMe: false,
            time: DateTime.now(),
          ));
        });
        _scrollToBottom();
      } else if (data['tipo'] == 'historial_synced') {
        // El servidor mando historial nuevo, recargamos desde la DB local
        _loadHistorialLocal();
      } else if (data['tipo'] == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['texto'] as String)),
        );
      }
    });
  }

  /// Carga el historial guardado localmente para esta conversacion.
  Future<void> _loadHistorialLocal() async {
    final me = _service.username;
    if (me == null) return;

    final rows = await LocalDbService().getConversation(me, widget.contactName);
    if (!mounted) return;

    setState(() {
      _messages.clear();
      for (final r in rows) {
        _messages.add(Message(
          from: r['de'] as String,
          text: r['texto'] as String,
          isMe: r['de'] == me,
          time: DateTime.tryParse(r['fecha'] as String? ?? '') ?? DateTime.now(),
        ));
      }
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _sub?.cancel();
    // Al salir de la conversacion, ya no es la activa
    if (_service.activeChatContact == widget.contactName) {
      _service.activeChatContact = null;
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _service.send(widget.contactName, text);
    setState(() {
      _messages.add(Message(
        from: _service.username!,
        text: text,
        isMe: true,
        time: DateTime.now(),
      ));
    });
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _avatarColor(widget.contactName),
              child: Text(
                widget.contactName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Text(
                  'online',
                  style: TextStyle(color: Color(0xFF25D366), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9C4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Los mensajes están cifrados 🔐',
                        style: TextStyle(color: Colors.brown[700], fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _buildBubble(_messages[i]),
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(Message msg) {
    final isMe = msg.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg.from,
                style: TextStyle(
                  color: _avatarColor(msg.from),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            Text(msg.text, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              _formatTime(msg.time),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: const Color(0xFFF0F0F0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF075E54),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _send,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
