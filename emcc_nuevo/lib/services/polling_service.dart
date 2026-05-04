import 'dart:async';
import 'database_service.dart';

class PollingService {
  static Timer? _timer;
  static Function(Map<String, dynamic>)? _onUpdate;
  static int _ultimoId = 0;

  static void startPolling({required Function(Map<String, dynamic>) onUpdate, int seconds = 5}) {
    _onUpdate = onUpdate;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: seconds), (_) => _checkUpdates());
  }

  static void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _checkUpdates() async {
    try {
      final db = await DatabaseService.database;
      final usuario = DatabaseService.usuario;
      if (usuario == null) return;
      final idFormateado = '${usuario.cargo}_${usuario.id}';
      
      final result = await db.rawQuery('SELECT MAX(id) as max_id FROM actividad WHERE id_end = ?', [idFormateado]);
      final nuevoId = result.first['max_id'] as int? ?? 0;
      
      if (nuevoId > _ultimoId) {
        _ultimoId = nuevoId;
        final nuevas = await db.query('actividad', where: 'id_end = ? AND id > ?', whereArgs: [idFormateado, _ultimoId - 5], orderBy: 'id DESC', limit: 5);
        final stats = await DatabaseService.getDashboard();
        _onUpdate?.call({'nuevas_actividades': nuevas, 'stats': stats['stats']});
      }
    } catch (e) {}
  }

  static void resetUltimoId() async {
    try {
      final db = await DatabaseService.database;
      final usuario = DatabaseService.usuario;
      if (usuario == null) return;
      final idFormateado = '${usuario.cargo}_${usuario.id}';
      final result = await db.rawQuery('SELECT MAX(id) as max_id FROM actividad WHERE id_end = ?', [idFormateado]);
      _ultimoId = result.first['max_id'] as int? ?? 0;
    } catch (e) {}
  }
}
