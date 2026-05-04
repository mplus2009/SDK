import 'package:flutter/material.dart';
import '../services/database_service.dart';

class EditarHorario extends StatefulWidget {
  const EditarHorario({super.key});
  @override
  State<EditarHorario> createState() => _EditarHorarioState();
}

class _EditarHorarioState extends State<EditarHorario> {
  String _grado = '10mo';
  int _peloton = 1;
  int _dia = 1;
  List<Map<String, dynamic>> _horario = [];
  List<Map<String, dynamic>> _asignaturas = [];
  bool _isLoading = true;
  final _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  final _nuevoTurno = TextEditingController(text: '1');
  final _nuevaDuracion = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    final db = await DatabaseService.database;
    _asignaturas = await db.query('asignaturas', orderBy: 'nombre');
    await _cargarHorario();
    setState(() => _isLoading = false);
  }

  Future<void> _cargarHorario() async {
    final db = await DatabaseService.database;
    final pelotonResult = await db.query('pelotones', where: 'grado = ? AND numero_peloton = ?', whereArgs: [_grado, _peloton], limit: 1);
    if (pelotonResult.isEmpty) { _horario = []; return; }
    final pelotonId = pelotonResult.first['id'];
    _horario = await db.rawQuery('SELECT h.*, a.nombre FROM horario_asignaturas h JOIN asignaturas a ON h.asignatura_id = a.id WHERE h.peloton_id = ? AND h.dia_semana = ? ORDER BY h.turno_inicio', [pelotonId, _dia]);
  }

  Future<void> _agregarTurno(int asignaturaId) async {
    final db = await DatabaseService.database;
    final pelotonResult = await db.query('pelotones', where: 'grado = ? AND numero_peloton = ?', whereArgs: [_grado, _peloton], limit: 1);
    if (pelotonResult.isEmpty) return;
    await db.insert('horario_asignaturas', {
      'peloton_id': pelotonResult.first['id'],
      'dia_semana': _dia,
      'turno_inicio': int.tryParse(_nuevoTurno.text) ?? 1,
      'turnos_duracion': int.tryParse(_nuevaDuracion.text) ?? 1,
      'asignatura_id': asignaturaId,
      'tipo_evento': 'asignatura',
      'semana': 'esta',
    });
    _cargarHorario();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turno agregado'), backgroundColor: Colors.green));
  }

  Future<void> _eliminarTurno(int id) async {
    final db = await DatabaseService.database;
    await db.delete('horario_asignaturas', where: 'id = ?', whereArgs: [id]);
    _cargarHorario();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turno eliminado'), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _nuevoTurno.dispose();
    _nuevaDuracion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diaTurnos = _horario;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Horario')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(value: _grado, decoration: const InputDecoration(labelText: 'Grado', border: OutlineInputBorder()), items: ['10mo', '11no', '12mo'].map((g) => DropdownMenuItem(value: g, child: Text('$g Grado'))).toList(), onChanged: (v) { setState(() => _grado = v ?? '10mo'); _cargarHorario(); })),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Pelotón', border: OutlineInputBorder()), keyboardType: TextInputType.number, controller: TextEditingController(text: '$_peloton'), onChanged: (v) { final p = int.tryParse(v); if (p != null) { _peloton = p; _cargarHorario(); } })),
                ]),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: List.generate(_dias.length, (i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(_dias[i].substring(0, 3)), selected: _dia == i + 1, onSelected: (v) { setState(() => _dia = i + 1); _cargarHorario(); }),
                  ))),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Turnos del día', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
                    const SizedBox(height: 15),
                    if (diaTurnos.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay turnos para este día', style: TextStyle(color: Color(0xFF94A3B8)))))
                    else
                      ...diaTurnos.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border(left: BorderSide(color: const Color(0xFF667EEA), width: 4))),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Turno ${t['turno_inicio']} - ${t['nombre']}', style: const TextStyle(fontWeight: FontWeight.w600)), Text('${t['turnos_duracion']} turno(s)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))])),
                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarTurno(t['id'] as int)),
                        ]),
                      )),
                  ]),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF10B981))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('➕ Agregar Turno', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                    const SizedBox(height: 15),
                    Row(children: [
                      Expanded(child: TextField(controller: _nuevoTurno, decoration: const InputDecoration(labelText: 'Turno #', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _nuevaDuracion, decoration: const InputDecoration(labelText: 'Duración', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 15),
                    Wrap(spacing: 8, children: _asignaturas.map((a) => ActionChip(
                      label: Text(a['nombre'] ?? '', style: const TextStyle(fontSize: 12)),
                      onPressed: () => _agregarTurno(a['id'] as int),
                      backgroundColor: const Color(0xFFE0E7FF),
                    )).toList()),
                  ]),
                ),
              ]),
            ),
    );
  }
}
