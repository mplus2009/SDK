import 'package:flutter/material.dart';
import '../services/database_service.dart';

class EditarReglas extends StatefulWidget {
  const EditarReglas({super.key});
  @override
  State<EditarReglas> createState() => _EditarReglasState();
}

class _EditarReglasState extends State<EditarReglas> {
  int _limite10mo = 15;
  int _limite11no = 11;
  int _limite12mo = 10;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarConfig();
  }

  Future<void> _cargarConfig() async {
    final db = await DatabaseService.database;
    final result = await db.query('alarma_config', limit: 1);
    if (result.isNotEmpty) {
      setState(() {
        _limite10mo = result.first['limite_10mo'] as int? ?? 15;
        _limite11no = result.first['limite_11no'] as int? ?? 11;
        _limite12mo = result.first['limite_12mo'] as int? ?? 10;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _guardar() async {
    final db = await DatabaseService.database;
    await db.update('alarma_config', {'limite_10mo': _limite10mo, 'limite_11no': _limite11no, 'limite_12mo': _limite12mo}, where: 'id = 1');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Reglas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('⚙️ Límites de Alarma por Grado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
                  const SizedBox(height: 25),
                  Text('10mo Grado: $_limite10mo deméritos', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(value: _limite10mo.toDouble(), min: 1, max: 50, divisions: 49, onChanged: (v) => setState(() => _limite10mo = v.toInt()), activeColor: const Color(0xFF1E3C72)),
                  const SizedBox(height: 15),
                  Text('11no Grado: $_limite11no deméritos', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(value: _limite11no.toDouble(), min: 1, max: 50, divisions: 49, onChanged: (v) => setState(() => _limite11no = v.toInt()), activeColor: const Color(0xFF1E3C72)),
                  const SizedBox(height: 15),
                  Text('12mo Grado: $_limite12mo deméritos', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(value: _limite12mo.toDouble(), min: 1, max: 50, divisions: 49, onChanged: (v) => setState(() => _limite12mo = v.toInt()), activeColor: const Color(0xFF1E3C72)),
                  const SizedBox(height: 30),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _guardar, icon: const Icon(Icons.save), label: const Text('Guardar Cambios'))),
                ]),
              ),
            ),
    );
  }
}
