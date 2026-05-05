import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ProfesorHorario extends StatefulWidget {
  const ProfesorHorario({super.key});
  @override
  State<ProfesorHorario> createState() => _ProfesorHorarioState();
}

class _ProfesorHorarioState extends State<ProfesorHorario> {
  List<Map<String, dynamic>> _horario = [];
  List<Map<String, dynamic>> _hoy = [];
  bool _loading = true;
  final _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  final int _hoyNum = DateTime.now().weekday;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = await DatabaseService.database;
    final u = DatabaseService.usuario;
    if (u == null) return;
    final prof = await db.query('profesor', where: 'id = ?', whereArgs: [u.id], limit: 1);
    if (prof.isEmpty) { setState(() => _loading = false); return; }
    final ocupacion = '${prof.first['ocupacion'] ?? ''}';
    final asig = await db.query('asignaturas', where: 'nombre LIKE ? OR abreviatura LIKE ?', whereArgs: ['%$ocupacion%', '%$ocupacion%'], limit: 1);
    if (asig.isEmpty) { setState(() => _loading = false); return; }
    final result = await db.rawQuery('SELECT h.*, a.nombre as asignatura, p.grado, p.numero_peloton FROM horario_asignaturas h JOIN asignaturas a ON h.asignatura_id = a.id JOIN pelotones p ON h.peloton_id = p.id WHERE h.asignatura_id = ? ORDER BY h.dia_semana, h.turno_inicio', [asig.first['id']]);
    setState(() { _horario = result; _hoy = result.where((h) => h['dia_semana'] == _hoyNum).toList(); _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Horario')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (_hoy.isNotEmpty) ...[
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hoy - ${_dias[_hoyNum-1]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            ..._hoy.map((t) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text('Turno ${t['turno_inicio']}: ${t['grado']}, Pelotón ${t['numero_peloton']}', style: const TextStyle(color: Colors.white)))),
          ])),
          const SizedBox(height: 20),
        ],
        ...List.generate(_dias.length, (i) {
          final diaTurnos = _horario.where((h) => h['dia_semana'] == i + 1).toList();
          if (diaTurnos.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: _hoyNum == i + 1 ? Border.all(color: const Color(0xFF10B981), width: 2) : null),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(_dias[i], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                if (_hoyNum == i + 1) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)), child: const Text('HOY', style: TextStyle(color: Colors.white, fontSize: 10))),
              ]),
              const SizedBox(height: 12),
              ...diaTurnos.map((t) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Turno ${t['turno_inicio']}', style: const TextStyle(fontWeight: FontWeight.w600)), Text('${t['grado']}, Pelotón ${t['numero_peloton']}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))]))),
            ]),
          );
        }),
      ]),
    );
  }
}
