class Message {
  final String from;
  final String text;
  final bool isMe;
  final DateTime time;

  Message({
    required this.from,
    required this.text,
    required this.isMe,
    required this.time,
  });
}
