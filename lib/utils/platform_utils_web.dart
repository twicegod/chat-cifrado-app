// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String getServerIp() {
  try {
    return html.window.location.hostname ?? '192.168.137.1';
  } catch (_) {
    return '192.168.137.1';
  }
}
