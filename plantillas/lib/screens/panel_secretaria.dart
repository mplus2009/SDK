import 'package:flutter/material.dart';
import '../services/database_service.dart';

class PanelSecretaria extends StatefulWidget {
  const PanelSecretaria({super.key});
  @override
  State<PanelSecretaria> createState() => _PanelSecretariaState();
}

class _PanelSecretariaState extends State<PanelSecretaria> {
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _ciController = TextEditingController();
  final _passwordController = TextEditingController();
  String _grado = '10mo';
  int _peloton = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _resultados = [];
  final _buscarController = TextEditingController();

  Future<void> _ingresarEstudiante() async {
    if (_nombreController.text.isEmpty || _apellidosController.text.isEmpty || _ciController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todos los campos son obligatorios'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);
    final db = await DatabaseService.database;
    final pass = _passwordController.text.isEmpty ? _ciController.text : _passwordController.text;
    await db.insert('estudiante', {
      'nombre': _nombreController.text, 'apellidos': _apellidosController.text,
      'ci': _ciController.text, 'password': pass, 'grado': _grado, 'peloton': _peloton,
      'ocupacion': 'ninguno', 'activo': 1,
    });
    _nombreController.clear(); _apellidosController.clear(); _ciController.clear(); _passwordController.clear();
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estudiante ingresado correctamente'), backgroundColor: Colors.green));
  }

  Future<void> _buscar() async {
    final db = await DatabaseService.database;
    final q = _buscarController.text;
    if (q.length < 2) return;
    final result = await db.query('estudiante', where: 'nombre LIKE ? OR apellidos LIKE ? OR ci LIKE ?', whereArgs: ['%$q%', '%$q%', '%$q%'], limit: 20);
    setState(() => _resultados = result);
  }

  Future<void> _toggleActivo(int id, int activo) async {
    final db = await DatabaseService.database;
    await db.update('estudiante', {'activo': activo == 1 ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
    _buscar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(activo == 1 ? 'Estudiante dado de baja' : 'Estudiante reactivado'), backgroundColor: Colors.green));
  }

  @override
  void dispose() {
    _nombreController.dispose(); _apellidosController.dispose();
    _ciController.dispose(); _passwordController.dispose(); _buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Secretaria')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('➕ Ingresar Nuevo Estudiante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
              const SizedBox(height: 15),
              TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _apellidosController, decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _ciController, decoration: const InputDecoration(labelText: 'CI', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(value: _grado, decoration: const InputDecoration(labelText: 'Grado', border: OutlineInputBorder()), items: ['10mo', '11no', '12mo'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _grado = v ?? '10mo'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Pelotón', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _peloton = int.tryParse(v) ?? 1)),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Contraseña (por defecto CI)', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _isLoading ? null : _ingresarEstudiante, icon: const Icon(Icons.person_add), label: const Text('Ingresar Estudiante'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)))),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🔍 Buscar Estudiante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: TextField(controller: _buscarController, decoration: const InputDecoration(hintText: 'Nombre, apellidos o CI...', border: OutlineInputBorder()))), const SizedBox(width: 10), ElevatedButton(onPressed: _buscar, child: const Text('Buscar'))]),
              const SizedBox(height: 15),
              ..._resultados.map((est) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: est['activo'] == 1 ? const Color(0xFFF8FAFC) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${est['nombre']} ${est['apellidos']}', style: const TextStyle(fontWeight: FontWeight.w600)), Text('CI: ${est['ci']}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))), Text('${est['grado']}, Pelotón ${est['peloton']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))])),
                  ElevatedButton(onPressed: () => _toggleActivo(est['id'] as int, est['activo'] as int), style: ElevatedButton.styleFrom(backgroundColor: est['activo'] == 1 ? Colors.red : Colors.green), child: Text(est['activo'] == 1 ? 'Dar baja' : 'Reactivar')),
                ]),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}
