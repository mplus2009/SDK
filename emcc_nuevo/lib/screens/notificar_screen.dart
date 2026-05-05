import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'escaner_screen.dart';

class NotificarScreen extends StatefulWidget {
  final dynamic destinatarioPrecargado;
  const NotificarScreen({super.key, this.destinatarioPrecargado});
  @override
  State<NotificarScreen> createState() => _NotificarScreenState();
}

class _NotificarScreenState extends State<NotificarScreen> {
  List<Map<String, dynamic>> _dest = [];
  List<Map<String, dynamic>> _acts = [];
  List<Map<String, dynamic>> _catMeritos = [];
  List<Map<String, dynamic>> _catDemeritos = [];
  String _tipo = 'merito';
  bool _loading = true;
  bool _sending = false;
  final _bc = TextEditingController();
  List<Map<String, dynamic>> _search = [];
  dynamic _sel;
  double _s10 = 1, _s11 = 1;
  int _s10min = 1, _s10max = 3, _s11min = 1, _s11max = 3;
  final _fc = TextEditingController();
  final _hc = TextEditingController();
  final _obs = TextEditingController();
  String? _catFiltro;

  @override
  void initState() {
    super.initState();
    _fc.text = DateTime.now().toString().split(' ')[0];
    _hc.text = DateTime.now().toString().substring(11, 16);
    if (widget.destinatarioPrecargado != null) _dest.add({'id': '${widget.destinatarioPrecargado['id']}', 'nombre': '${widget.destinatarioPrecargado['nombre']} ${widget.destinatarioPrecargado['apellidos']}', 'ci': '${widget.destinatarioPrecargado['CI']??widget.destinatarioPrecargado['ci']}', 'grado': '${widget.destinatarioPrecargado['grado']??'10mo'}'});
    _load();
  }

  Future<void> _load() async {
    _catMeritos = await DatabaseService.getCatalogo('merito');
    _catDemeritos = await DatabaseService.getCatalogo('demerito');
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _catActual => _tipo == 'merito' ? _catMeritos : _catDemeritos;
  Map<String, List<String>> _grupos() {
    final g = <String, List<String>>{'10mo': [], '11no': []};
    for (final d in _dest) {
      final grado = d['grado'] ?? '10mo';
      if (grado == '10mo') { g['10mo']!.add(d['nombre']); } else { g['11no']!.add("${d['nombre']} ($grado)"); }
    }
    return g;
  }

  List<int> _parseRango(dynamic s) {
    if (s == null) return [1, 1];
    final p = s.toString().split('-');
    return [int.tryParse(p[0]) ?? 1, int.tryParse(p.length > 1 ? p[1] : p[0]) ?? 1];
  }

  int _calcCantidad() {
    final g = _grupos();
    if (g['10mo']!.isNotEmpty) return _s10.toInt();
    if (g['11no']!.isNotEmpty) return _s11.toInt();
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final puede = _dest.isNotEmpty && _acts.isNotEmpty;
    final g = _grupos();
    final hay10 = g['10mo']!.isNotEmpty;
    final hay11 = g['11no']!.isNotEmpty;
    final catUnicas = <String>{};
    for (final c in _catActual) { catUnicas.add(c['categoria']??''); }

    return Scaffold(
      appBar: AppBar(title: const Text('Notificar')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Destinatarios
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Destinatarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ..._dest.map((d) => Chip(label: Text(d['nombre']), onDeleted: () => setState(() => _dest.remove(d)))),
          TextField(controller: _bc, decoration: const InputDecoration(hintText: 'Buscar...'), onChanged: (q) async { if (q.length > 1) setState(() => _search = DatabaseService.buscarEstudiantes(q).then((v) => setState(() => _search = v)) as List<Map<String, dynamic>>); }),
          ..._search.map((e) => ListTile(title: Text('${e['nombre']} ${e['apellidos']}'), onTap: () { _dest.add({'id': '${e['id']}', 'nombre': '${e['nombre']} ${e['apellidos']}', 'ci': '${e['CI']}', 'grado': '${e['grado']??'10mo'}'}); setState(() { _search = []; _bc.clear(); }); })),
          OutlinedButton.icon(onPressed: () async { final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EscanerScreen())); if (r != null) setState(() => _dest.addAll(r as List<Map<String, dynamic>>)); }, icon: const Icon(Icons.qr_code), label: const Text('Escanear QR')),
        ])),
        const SizedBox(height: 20),
        // Actividades
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Actividades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Row(children: [
            Expanded(child: ChoiceChip(label: const Text('Mérito'), selected: _tipo == 'merito', onSelected: (_) => setState(() => _tipo = 'merito'))),
            const SizedBox(width: 8),
            Expanded(child: ChoiceChip(label: const Text('Demérito'), selected: _tipo == 'demerito', onSelected: (_) => setState(() => _tipo = 'demerito'))),
          ]),
          // Dropdown categoría
          DropdownButtonFormField<String>(value: _catFiltro, decoration: const InputDecoration(labelText: 'Categoría'), items: [const DropdownMenuItem(value: null, child: Text('Todas')), ...catUnicas.map((c) => DropdownMenuItem(value: c, child: Text(c)))], onChanged: (v) => setState(() => _catFiltro = v)),
          // Lista filtrada
          ..._catActual.where((a) => _catFiltro == null || a['categoria'] == _catFiltro).map((a) => ListTile(
            title: Text(_tipo == 'merito' ? '${a['causa']}' : '${a['falta']}'),
            subtitle: Text(_tipo == 'merito' ? '+${a['meritos']}' : '10mo: ${a['demeritos_10mo']} | 11/12: ${a['demeritos_11_12']}'),
            trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
            onTap: () => setState(() => _sel = a),
          )),
          // SLIDERS (sin campo valor)
          if (_sel != null && _tipo == 'demerito') ...[
            if (hay10)
              Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(top: 10), decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(14)), child: Column(children: [
                const Text('Rango 10mo', style: TextStyle(fontWeight: FontWeight.w700)),
                Slider(min: _s10min.toDouble(), max: _s10max.toDouble(), value: _s10, onChanged: (v) => setState(() => _s10 = v)),
                Text('${_s10.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ])),
            if (hay11)
              Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(top: 10), decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(14)), child: Column(children: [
                const Text('Rango 11no/12mo', style: TextStyle(fontWeight: FontWeight.w700)),
                Slider(min: _s11min.toDouble(), max: _s11max.toDouble(), value: _s11, onChanged: (v) => setState(() => _s11 = v)),
                Text('${_s11.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ])),
          ],
          if (_sel != null)
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { _acts.add({'nombre': _tipo=='merito'?_sel['causa']:_sel['falta'], 'cantidad': _calcCantidad(), 'tipo': _tipo, 'categoria': _sel['categoria']}); setState(() => _sel = null); }, child: const Text('Agregar'))),
          // Actividades agregadas
          ..._acts.map((a) => ListTile(title: Text(a['nombre']), subtitle: Text('${a['tipo']=='merito'?'+':'-'}${a['cantidad']}'), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _acts.remove(a))))),
        ])),
        const SizedBox(height: 20),
        // Fecha/Hora
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Row(children: [
          Expanded(child: TextField(controller: _fc, decoration: const InputDecoration(labelText: 'Fecha'))),
          const SizedBox(width: 12),
          Expanded(child: TextField(controller: _hc, decoration: const InputDecoration(labelText: 'Hora'))),
        ])),
        const SizedBox(height: 20),
        // Observaciones
        TextField(controller: _obs, decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder())),
        const SizedBox(height: 20),
        // Botón enviar
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: puede && !_sending ? () async { setState(() => _sending = true); await DatabaseService.enviarNotificacion({'destinatarios': _dest, 'actividades': _acts, 'fecha': _fc.text, 'hora': _hc.text, 'id_star': '${DatabaseService.usuario?.id}', 'cargo_notificador': DatabaseService.usuario?.cargo}); setState(() { _sending = false; _dest = []; _acts = []; }); } : null, icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send), label: const Text('Enviar'))),
      ]),
    );
  }
}
