import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para guardar/leer datos del login en el almacenamiento local
/// del dispositivo (SharedPreferences). Sobrevive a cerrar la app por
/// completo, pero se borra cuando el usuario hace logout.
class PrefsService {
  static const _kIp = 'server_ip';
  static const _kUser = 'username';

  /// Guarda el login del usuario para auto-login en la proxima apertura.
  static Future<void> saveLogin(String ip, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIp, ip);
    await prefs.setString(_kUser, name);
  }

  /// Carga el login guardado. Devuelve null si no hay nada guardado.
  static Future<({String ip, String name})?> loadLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(_kIp);
    final name = prefs.getString(_kUser);
    if (ip == null || name == null) return null;
    return (ip: ip, name: name);
  }

  /// Borra los datos de login (al cerrar sesion).
  static Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIp);
    await prefs.remove(_kUser);
  }
}
