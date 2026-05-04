import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ProfesorHorario extends StatefulWidget {
  const ProfesorHorario({super.key});
  @override
  State<ProfesorHorario> createState() => _ProfesorHorarioState();
}

class _ProfesorHorarioState extends State<ProfesorHorario> {
  String _asignaturaNombre = '';
  List<Map<String, dynamic>> _horario = [];
  List<Map<String, dynamic>> _hoy = [];
  bool _isLoading = true;
  final _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
  final int _diaActual = DateTime.now().weekday;

  @override
  void initState() {
    super.initState();
    _cargarHorario();
  }

  Future<void> _cargarHorario() async {
    final db = await DatabaseService.database;
    final usuario = DatabaseService.usuario;
    if (usuario == null) return;
    final profResult = await db.query('profesor', where: 'id = ?', whereArgs: [usuario.id], limit: 1);
    if (profResult.isEmpty) { setState(() => _isLoading = false); return; }
    final ocupacion = profResult.first['ocupacion'] ?? '';
    _asignaturaNombre = ocupacion.replaceAll('_', ' ');
    final asigResult = await db.query('asignaturas', where: 'nombre LIKE ? OR abreviatura LIKE ?', whereArgs: ['%$_asignaturaNombre%', '%$_asignaturaNombre%'], limit: 1);
    if (asigResult.isEmpty) { setState(() => _isLoading = false); return; }
    final asigId = asigResult.first['id'];
    final result = await db.rawQuery('SELECT h.*, a.nombre as asignatura, p.grado, p.numero_peloton FROM horario_asignaturas h JOIN asignaturas a ON h.asignatura_id = a.id JOIN pelotones p ON h.peloton_id = p.id WHERE h.asignatura_id = ? ORDER BY h.dia_semana, h.turno_inicio', [asigId]);
    setState(() { _horario = result; _hoy = result.where((h) => h['dia_semana'] == _diaActual).toList(); _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Horario')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
                  child: Row(children: [
                    Container(width: 50, height: 50, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.book, color: Colors.white, size: 28)),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(DatabaseService.usuario?.nombreCompleto ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1E3C72))), Text(_asignaturaNombre.capitalize(), style: const TextStyle(color: Color(0xFF667EEA), fontWeight: FontWeight.w600))])),
                  ]),
                ),
                const SizedBox(height: 20),
                if (_hoy.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), borderRadius: BorderRadius.circular(22)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [const Icon(Icons.today, color: Colors.white), const SizedBox(width: 8), Text('Hoy - ${_dias[_diaActual-1]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))]),
                      const SizedBox(height: 15),
                      ..._hoy.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Center(child: Text('T${t['turno_inicio']}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF10B981))))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${t['grado']}, Pelotón ${t['numero_peloton']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), Text('${t['turnos_duracion']} turno(s)', style: const TextStyle(color: Colors.white70, fontSize: 13))])),
                        ]),
                      )),
                    ]),
                  ),
                Text('Toda la Semana', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
                const SizedBox(height: 15),
                ...List.generate(_dias.length, (i) {
                  final diaTurnos = _horario.where((h) => h['dia_semana'] == i + 1).toList();
                  if (diaTurnos.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: _diaActual == i + 1 ? Border.all(color: const Color(0xFF10B981), width: 2) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Text(_dias[i], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF1E3C72))), if (_diaActual == i + 1) Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)), child: const Text('HOY', style: TextStyle(color: Colors.white, fontSize: 10)))], const Spacer()]),
                      const SizedBox(height: 12),
                      ...diaTurnos.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: const Color(0xFF667EEA), width: 4))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Turno ${t['turno_inicio']}${t['turnos_duracion'] > 1 ? ' - ${t['turno_inicio'] + t['turnos_duracion'] - 1}' : ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(children: [Text('${t['grado']}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))), const SizedBox(width: 15), Text('Pelotón ${t['numero_peloton']}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))]),
                        ]),
                      )),
                    ]),
                  );
                }),
              ]),
            ),
    );
  }
}

extension StringCap on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
