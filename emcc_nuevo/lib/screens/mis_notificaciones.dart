import 'package:flutter/material.dart';
import '../services/database_service.dart';

class MisNotificaciones extends StatefulWidget {
  const MisNotificaciones({super.key});
  @override
  State<MisNotificaciones> createState() => _MisNotificacionesState();
}

class _MisNotificacionesState extends State<MisNotificaciones> {
  List<Map<String, dynamic>> _notificaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final db = await DatabaseService.database;
    final usuario = DatabaseService.usuario;
    if (usuario == null) return;
    final idFormateado = '${usuario.cargo}_${usuario.id}';
    final result = await db.query('actividad', where: 'id_star = ?', whereArgs: [idFormateado], orderBy: 'fecha DESC, hora DESC', limit: 50);
    if (!mounted) return;
    setState(() { _notificaciones = result; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Notificaciones')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? const Center(child: Text('No hay notificaciones enviadas', style: TextStyle(color: Color(0xFF64748B))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notificaciones.length,
                  itemBuilder: (ctx, i) {
                    final n = _notificaciones[i];
                    final esMerito = n['tipo'] == 'merito';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border(left: BorderSide(color: esMerito ? const Color(0xFF10B981) : const Color(0xFFEF4444), width: 4)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(esMerito ? Icons.emoji_events : Icons.warning_amber, color: esMerito ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(n['falta_causa'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF1E293B)))),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: esMerito ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)), child: Text('${esMerito ? "+" : "-"}${n['cantidad']}', style: TextStyle(fontWeight: FontWeight.w700, color: esMerito ? const Color(0xFF065F46) : const Color(0xFF991B1B)))),
                        ]),
                        const SizedBox(height: 8),
                        Text('${n['fecha']} ${n['hora']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ]),
                    );
                  },
                ),
    );
  }
}
