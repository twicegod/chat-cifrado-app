import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Servicio de cache local con SQLite.
///
/// Guarda todos los mensajes (enviados y recibidos) en una DB local del
/// dispositivo. Permite que la app muestre el historial inmediatamente al
/// abrir un chat, sin esperar al servidor.
///
/// En Flutter Web no usa SQLite (las APIs no funcionan igual), todas las
/// operaciones se vuelven no-op. La app sigue funcionando, solo que sin
/// cache local.
class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;
  bool get _disabled => kIsWeb;

  /// Inicializa la DB. Llamar una vez al arrancar la app o al hacer login.
  Future<void> init() async {
    if (_disabled) return;
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'chat_cache.db');

    _db = await openDatabase(
      fullPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE mensajes (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id    INTEGER UNIQUE,
            de           TEXT NOT NULL,
            para         TEXT NOT NULL,
            texto        TEXT NOT NULL,
            fecha        TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_mensajes_par ON mensajes(de, para, fecha)',
        );
      },
    );
  }

  /// Guarda un mensaje recibido del servidor (con ID del servidor).
  /// Si ya existe (mismo server_id) no lo duplica.
  Future<void> saveReceivedMessage({
    required int? serverId,
    required String de,
    required String para,
    required String texto,
    String? fecha,
  }) async {
    if (_disabled || _db == null) return;
    await _db!.insert(
      'mensajes',
      {
        'server_id': serverId,
        'de': de,
        'para': para,
        'texto': texto,
        'fecha': fecha ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Guarda un mensaje enviado por el usuario (sin ID del servidor todavia).
  Future<void> saveSentMessage({
    required String de,
    required String para,
    required String texto,
  }) async {
    if (_disabled || _db == null) return;
    await _db!.insert('mensajes', {
      'server_id': null,
      'de': de,
      'para': para,
      'texto': texto,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  /// Sincroniza el historial completo recibido del servidor.
  /// Inserta solo los que no existen localmente (segun server_id).
  Future<void> syncHistorial(List<dynamic> mensajes) async {
    if (_disabled || _db == null) return;
    final batch = _db!.batch();
    for (final m in mensajes) {
      batch.insert(
        'mensajes',
        {
          'server_id': m['id'],
          'de': m['de'],
          'para': m['para'],
          'texto': m['texto'],
          'fecha': m['fecha'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Devuelve la conversacion entre dos usuarios, ordenada de vieja a nueva.
  Future<List<Map<String, dynamic>>> getConversation(
    String me,
    String other,
  ) async {
    if (_disabled || _db == null) return [];
    return await _db!.rawQuery(
      '''
      SELECT * FROM mensajes
      WHERE (de = ? AND para = ?) OR (de = ? AND para = ?)
      ORDER BY datetime(fecha) ASC, id ASC
      ''',
      [me, other, other, me],
    );
  }

  /// Devuelve el ultimo mensaje de cada conversacion (para preview en lista
  /// de contactos).
  Future<Map<String, String>> getLastMessagePerContact(String me) async {
    if (_disabled || _db == null) return {};
    final rows = await _db!.rawQuery(
      '''
      SELECT
        CASE WHEN de = ? THEN para ELSE de END AS contacto,
        texto,
        fecha
      FROM mensajes
      WHERE de = ? OR para = ?
      ORDER BY datetime(fecha) DESC
      ''',
      [me, me, me],
    );
    final result = <String, String>{};
    for (final r in rows) {
      final contacto = r['contacto'] as String;
      if (!result.containsKey(contacto)) {
        result[contacto] = r['texto'] as String;
      }
    }
    return result;
  }

  /// Borra TODA la DB local (al cerrar sesion).
  Future<void> clearAll() async {
    if (_disabled || _db == null) return;
    await _db!.delete('mensajes');
  }

  /// Cantidad total de mensajes guardados (para debugging).
  Future<int> count() async {
    if (_disabled || _db == null) return 0;
    final result = await _db!.rawQuery('SELECT COUNT(*) as c FROM mensajes');
    return result.first['c'] as int;
  }
}
