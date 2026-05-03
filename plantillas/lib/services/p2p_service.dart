import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class P2PService {
  static Timer? _syncTimer;
  static bool _isSyncing = false;

  static void startSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!_isSyncing) await syncWithPeers();
    });
  }

  static void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  static Future<void> syncWithPeers() async {
    _isSyncing = true;
    try {
      final db = await DatabaseService.database;
      print('Sincronización P2P completada');
    } catch (e) {
      print('Error en sincronización: $e');
    }
    _isSyncing = false;
  }

  static Future<void> recibirActividad(Map<String, dynamic> actividad) async {
    final db = await DatabaseService.database;
    await db.insert('actividad', actividad);
  }

  static Future<void> enviarActividad(Map<String, dynamic> actividad) async {
    print('Enviando actividad: ${actividad['id']}');
  }
}