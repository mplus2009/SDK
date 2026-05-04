import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CambioMando extends StatefulWidget {
  const CambioMando({super.key});
  @override
  State<CambioMando> createState() => _CambioMandoState();
}

class _CambioMandoState extends State<CambioMando> {
  String _grado = '11no';
  List<Map<String, dynamic>> _estudiantes = [];
  bool _isLoading = true;

  final _ocupaciones = ['ninguno', 'activista', 'jefe_escuadra', 'politico_peloton', '2do_jefe_peloton', '1er_jefe_peloton', 'politico_compania', '2do_jefe_compania', '1er_jefe_compania', 'sargento_mayor', '2do_jefe_batallon', 'jefe_batallon'];

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
  }

  Future<void> _cargarEstudiantes() async {
    setState(() => _isLoading = true);
    final db = await DatabaseService.database;
    final result = await db.query('estudiante', where: 'grado = ?', whereArgs: [_grado], orderBy: 'apellidos, nombre');
    setState(() { _estudiantes = result; _isLoading = false; });
  }

  Future<void> _actualizarOcupacion(int id, String ocupacion) async {
    final db = await DatabaseService.database;
    await db.update('estudiante', {'ocupacion': ocupacion}, where: 'id = ?', whereArgs: [id]);
    _cargarEstudiantes();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cargo actualizado'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambio de Mando')),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: _grado, decoration: const InputDecoration(labelText: 'Seleccionar Grado', border: OutlineInputBorder()),
            items: ['10mo', '11no', '12mo'].map((g) => DropdownMenuItem(value: g, child: Text('$g Grado'))).toList(),
            onChanged: (v) { setState(() => _grado = v ?? '11no'); _cargarEstudiantes(); },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _estudiantes.length,
                  itemBuilder: (ctx, i) {
                    final est = _estudiantes[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${est['nombre']} ${est['apellidos']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Actual: ${est['ocupacion'] ?? 'ninguno'}'.replaceAll('_', ' '), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ])),
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                            value: est['ocupacion'] ?? 'ninguno',
                            decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                            items: _ocupaciones.map((o) => DropdownMenuItem(value: o, child: Text(o.replaceAll('_', ' '), style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => _actualizarOcupacion(est['id'] as int, v ?? 'ninguno'),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
