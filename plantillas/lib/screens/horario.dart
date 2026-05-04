import 'package:flutter/material.dart';
import '../services/database_service.dart';

class HorarioScreen extends StatefulWidget {
  const HorarioScreen({super.key});
  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  String _grado = '10mo';
  int _peloton = 1;
  List<Map<String, dynamic>> _horario = [];
  bool _isLoading = true;
  final _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  @override
  void initState() {
    super.initState();
    _grado = DatabaseService.usuario?.grado ?? '10mo';
    _peloton = DatabaseService.usuario?.peloton ?? 1;
    _cargarHorario();
  }

  Future<void> _cargarHorario() async {
    setState(() => _isLoading = true);
    final db = await DatabaseService.database;
    final pelotonResult = await db.query('pelotones', where: 'grado = ? AND numero_peloton = ?', whereArgs: [_grado, _peloton], limit: 1);
    if (pelotonResult.isEmpty) { setState(() => _isLoading = false); return; }
    final pelotonId = pelotonResult.first['id'];
    final result = await db.rawQuery('SELECT h.*, a.nombre as asignatura FROM horario_asignaturas h JOIN asignaturas a ON h.asignatura_id = a.id WHERE h.peloton_id = ? ORDER BY h.dia_semana, h.turno_inicio', [pelotonId]);
    setState(() { _horario = result; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Horario')),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: DropdownButtonFormField<String>(value: _grado, decoration: const InputDecoration(labelText: 'Grado', border: OutlineInputBorder()), items: ['10mo', '11no', '12mo'].map((g) => DropdownMenuItem(value: g, child: Text('$g Grado'))).toList(), onChanged: (v) { setState(() => _grado = v ?? '10mo'); _cargarHorario(); })),
            const SizedBox(width: 12),
            Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Pelotón', border: OutlineInputBorder()), keyboardType: TextInputType.number, controller: TextEditingController(text: '$_peloton'), onChanged: (v) { final p = int.tryParse(v); if (p != null) { _peloton = p; _cargarHorario(); } })),
          ]),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _horario.isEmpty
                  ? const Center(child: Text('No hay horario configurado', style: TextStyle(color: Color(0xFF64748B))))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _dias.length,
                      itemBuilder: (ctx, diaIndex) {
                        final diaTurnos = _horario.where((h) => h['dia_semana'] == diaIndex + 1).toList();
                        if (diaTurnos.isEmpty) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_dias[diaIndex], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
                            const SizedBox(height: 12),
                            ...diaTurnos.map((t) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: const Color(0xFF667EEA), width: 4))),
                              child: Row(children: [
                                Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(10)), child: Center(child: Text('T${t['turno_inicio']}', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF667EEA))))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t['asignatura'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)), Text('${t['turnos_duracion']} turno(s)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))])),
                              ]),
                            )),
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
