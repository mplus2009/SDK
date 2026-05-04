import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CambiarCargos extends StatefulWidget {
  const CambiarCargos({super.key});
  @override
  State<CambiarCargos> createState() => _CambiarCargosState();
}

class _CambiarCargosState extends State<CambiarCargos> {
  final _buscarController = TextEditingController();
  String _filtro = 'todos';
  List<Map<String, dynamic>> _resultados = [];
  bool _buscando = false;

  final Map<String, List<String>> _ocupaciones = {
    'estudiante': ['ninguno', 'activista', 'jefe_escuadra', 'politico_peloton', '2do_jefe_peloton', '1er_jefe_peloton', 'politico_compania', '2do_jefe_compania', '1er_jefe_compania', 'sargento_mayor', '2do_jefe_batallon', 'jefe_batallon'],
    'oficial': ['teniente', 'primer_teniente', 'capitan', 'mayor', 'teniente_coronel', 'coronel', 'primer_coronel'],
    'profesor': ['matematicas', 'historia', 'fisica', 'quimica', 'ingles', 'literatura_lengua', 'preparacion_fisica', 'cultura_politica', 'preparacion_ciudadana', 'panorama_cultura_cubana', 'informatica', 'biblioteca', 'biologia', 'geografia', 'secretaria', 'otro'],
  };

  Future<void> _buscar() async {
    final q = _buscarController.text;
    if (q.length < 2) return;
    setState(() => _buscando = true);
    final db = await DatabaseService.database;
    final resultados = <Map<String, dynamic>>[];
    final search = '%$q%';
    
    if (_filtro == 'todos' || _filtro == 'estudiante') {
      final r = await db.query('estudiante', where: 'nombre LIKE ? OR apellidos LIKE ? OR ci LIKE ?', whereArgs: [search, search, search], limit: 10);
      for (final e in r) { e['tipo'] = 'estudiante'; resultados.add(e); }
    }
    if (_filtro == 'todos' || _filtro == 'profesor') {
      final r = await db.query('profesor', where: 'nombre LIKE ? OR apellidos LIKE ? OR ci LIKE ?', whereArgs: [search, search, search], limit: 10);
      for (final e in r) { e['tipo'] = 'profesor'; resultados.add(e); }
    }
    if (_filtro == 'todos' || _filtro == 'oficial') {
      final r = await db.query('oficial', where: 'nombre LIKE ? OR apellidos LIKE ? OR ci LIKE ?', whereArgs: [search, search, search], limit: 10);
      for (final e in r) { e['tipo'] = 'oficial'; resultados.add(e); }
    }
    setState(() { _resultados = resultados; _buscando = false; });
  }

  Future<void> _actualizarOcupacion(String tipo, int id, String ocupacion) async {
    final db = await DatabaseService.database;
    await db.update(tipo, {'ocupacion': ocupacion}, where: 'id = ?', whereArgs: [id]);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cargo actualizado'), backgroundColor: Colors.green));
    _buscar();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar Cargos')),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(controller: _buscarController, decoration: const InputDecoration(hintText: 'Buscar por nombre o CI...', border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _buscar, child: const Text('Buscar')),
            ]),
            const SizedBox(height: 10),
            Row(children: ['todos', 'estudiante', 'profesor', 'oficial'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(f == 'todos' ? 'Todos' : f.capitalize()), selected: _filtro == f, onSelected: (v) => setState(() => _filtro = f)),
            )).toList()),
          ]),
        ),
        Expanded(
          child: _buscando
              ? const Center(child: CircularProgressIndicator())
              : _resultados.isEmpty
                  ? const Center(child: Text('Ingresa un término de búsqueda', style: TextStyle(color: Color(0xFF64748B))))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _resultados.length,
                      itemBuilder: (ctx, i) {
                        final u = _resultados[i];
                        final tipo = u['tipo'] as String;
                        final ocupaciones = _ocupaciones[tipo] ?? [];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${u['nombre']} ${u['apellidos']}', style: const TextStyle(fontWeight: FontWeight.w600)), Text('${tipo.capitalize()} - CI: ${u['ci']}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))])),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)), child: Text(tipo.capitalize(), style: const TextStyle(fontSize: 11))),
                            ]),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: u['ocupacion'] ?? ocupaciones.first,
                              decoration: const InputDecoration(labelText: 'Ocupación', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                              items: ocupaciones.map((o) => DropdownMenuItem(value: o, child: Text(o.replaceAll('_', ' '), style: const TextStyle(fontSize: 13)))).toList(),
                              onChanged: (v) => _actualizarOcupacion(tipo, u['id'] as int, v ?? ocupaciones.first),
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

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
