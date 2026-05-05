import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/database_service.dart';
import '../services/mesh_service.dart';
import 'escaner_screen.dart';

class NotificarScreen extends StatefulWidget {
  final dynamic destinatarioPrecargado;
  const NotificarScreen({super.key, this.destinatarioPrecargado});
  @override
  State<NotificarScreen> createState() => _NotificarScreenState();
}

class _NotificarScreenState extends State<NotificarScreen> {
  final _fc = TextEditingController();
  final _hc = TextEditingController();
  List<Map<String, dynamic>> _dest = [];
  List<Map<String, dynamic>> _acts = [];
  List<Map<String, dynamic>> _cat = [];
  String _tipo = 'merito';
  bool _loading = false;
  bool _sending = false;
  final _bc = TextEditingController();
  List<Map<String, dynamic>> _search = [];
  final _cc = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _fc.text = DateTime.now().toString().split(' ')[0];
    _hc.text = DateTime.now().toString().substring(11, 16);
    if (widget.destinatarioPrecargado != null) {
      _dest.add({'id': '${widget.destinatarioPrecargado['id']}', 'nombre': '${widget.destinatarioPrecargado['nombre']} ${widget.destinatarioPrecargado['apellidos']}', 'ci': '${widget.destinatarioPrecargado['CI']}', 'grado': '${widget.destinatarioPrecargado['grado']??'10mo'}'});
    }
    _loadCat();
  }

  Future<void> _loadCat() async {
    setState(() => _loading = true);
    _cat = await DatabaseService.getCatalogo('meritos');
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final puede = _dest.isNotEmpty && _acts.isNotEmpty;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: Text('Notificar Actividad', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              // SECCIÓN DESTINATARIOS
              _buildSection('Destinatarios', Icons.people, const Color(0xFF667EEA), [
                if (_dest.isEmpty)
                  _buildEmpty('No hay destinatarios')
                else
                  Wrap(spacing: 8, children: _dest.map((d) => Chip(
                    avatar: CircleAvatar(backgroundColor: const Color(0xFF667EEA), child: Text(d['nombre']?[0] ?? '?', style: const TextStyle(color: Colors.white, fontSize: 12))),
                    label: Text(d['nombre'], style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _dest.remove(d)),
                  )).toList()),
                const SizedBox(height: 12),
                TextField(
                  controller: _bc,
                  decoration: InputDecoration(hintText: 'Buscar estudiante...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFFF0F2F5)),
                  onChanged: (q) async {
                    if (q.length > 1) {
                      final r = await DatabaseService.buscarEstudiantes(q);
                      setState(() => _search = r);
                    }
                  },
                ),
                ..._search.map((e) => ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFF1E3C72), child: Text('${e['nombre']?[0]??''}', style: const TextStyle(color: Colors.white))),
                  title: Text('${e['nombre']} ${e['apellidos']}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text('CI: ${e['CI']}'),
                  trailing: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
                  onTap: () {
                    _dest.add({'id': '${e['id']}', 'nombre': '${e['nombre']} ${e['apellidos']}', 'ci': '${e['CI']}', 'grado': '${e['grado']??'10mo'}'});
                    setState(() { _search = []; _bc.clear(); });
                  },
                )),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () async {
                  final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EscanerScreen()));
                  if (r != null) setState(() => _dest.addAll(r as List<Map<String, dynamic>>));
                }, icon: const Icon(Icons.qr_code), label: const Text('Escanear QR'))),
              ]).animate().fadeIn(duration: 300.ms),
              
              const SizedBox(height: 16),
              
              // SECCIÓN ACTIVIDADES
              _buildSection('Actividades', Icons.list_alt, const Color(0xFF10B981), [
                Row(children: [
                  Expanded(child: _tipoBtn('Mérito', 'merito', Icons.star, const Color(0xFF10B981))),
                  const SizedBox(width: 12),
                  Expanded(child: _tipoBtn('Demérito', 'demerito', Icons.warning, const Color(0xFFEF4444))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: _cc, decoration: InputDecoration(labelText: 'Valor', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFFF0F2F5)), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                if (_acts.isNotEmpty)
                  ..._acts.asMap().entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: e.value['tipo'] == 'merito' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Expanded(child: Text(e.value['nombre'], style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
                      Text('${e.value['cantidad']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.delete, size: 18), onPressed: () => setState(() => _acts.removeAt(e.key))),
                    ]),
                  )),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: () {
                    _acts.add({'nombre': 'Actividad ${_acts.length + 1}', 'cantidad': int.tryParse(_cc.text) ?? 1, 'tipo': _tipo});
                    setState(() => _cc.text = '1');
                  },
                  icon: const Icon(Icons.add), label: const Text('Agregar Actividad'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
              ]).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 16),
              
              // FECHA Y HORA
              _buildSection('Fecha y Hora', Icons.schedule, const Color(0xFFF59E0B), [
                Row(children: [
                  Expanded(child: TextField(controller: _fc, decoration: InputDecoration(labelText: 'Fecha', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFFF0F2F5)), readOnly: true)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _hc, decoration: InputDecoration(labelText: 'Hora', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFFF0F2F5)), readOnly: true)),
                ]),
              ]).animate().fadeIn(delay: 300.ms),
              
              const SizedBox(height: 24),
              
              // BOTÓN ENVIAR
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: puede && !_sending ? () async {
                    setState(() => _sending = true);
                    final data = {'destinatarios': _dest, 'actividades': _acts, 'fecha': _fc.text, 'hora': _hc.text, 'id_star': '${DatabaseService.usuario?.id}', 'cargo_notificador': DatabaseService.usuario?.cargo};
                    await DatabaseService.enviarNotificacion(data);
                    try { await MeshService().sendToAll(data); } catch (_) {}
                    setState(() { _sending = false; _dest = []; _acts = []; });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Notificación enviada'), backgroundColor: Colors.green));
                  } : null,
                  icon: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.send, size: 24),
                  label: Text(_sending ? 'Enviando...' : 'Enviar Notificación', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: puede ? const Color(0xFF1E3C72) : Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ]),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 8), Text(title, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E3C72)))]),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }

  Widget _tipoBtn(String label, String tipo, IconData icon, Color color) {
    final active = _tipo == tipo;
    return GestureDetector(
      onTap: () => setState(() => _tipo = tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(14),
          border: active ? Border.all(color: color, width: 2) : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: active ? color : Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: active ? color : Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(text, style: GoogleFonts.poppins(color: Colors.grey))),
    );
  }
}
