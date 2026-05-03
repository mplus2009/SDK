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
  List<Map<String, dynamic>> _destinatarios = [];
  List<Map<String, dynamic>> _actividadesAgregadas = [];
  List<dynamic> _catalogoMeritos = [];
  List<dynamic> _catalogoDemeritos = [];

  String _tipoActual = 'merito';
  dynamic _actividadSeleccionada;
  bool _isLoading = true;
  bool _enviando = false;

  bool _usandoCuentaTemporal = false;
  String _notificadorNombre = '';
  String _notificadorCargo = '';
  int _idStar = 0;
  String _tipoNotificador = 'cuenta';
  String _cargoNotificador = '';

  final _buscarController = TextEditingController();
  final _fechaController = TextEditingController();
  final _horaController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _tempNombreController = TextEditingController();
  final _tempPasswordController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');

  double _slider10mo = 1;
  double _slider11_12 = 1;
  int _sliderMin10mo = 1, _sliderMax10mo = 3;
  int _sliderMin11_12 = 1, _sliderMax11_12 = 3;

  List<dynamic> _resultadosBusqueda = [];
  List<dynamic> _resultadosActividad = [];
  String? _categoriaFiltro;

  @override
  void initState() {
    super.initState();
    _fechaController.text = DateTime.now().toString().split(' ')[0];
    _horaController.text = DateTime.now().toString().substring(11, 16);
    final usuario = DatabaseService.usuario;
    if (usuario != null) {
      _notificadorNombre = usuario.nombreCompleto;
      _notificadorCargo = usuario.cargo;
      _idStar = usuario.id;
      _cargoNotificador = usuario.cargo;
    }
    if (widget.destinatarioPrecargado != null) {
      _destinatarios.add({
        'id': '${widget.destinatarioPrecargado['id']}',
        'nombre': '${widget.destinatarioPrecargado['nombre']} ${widget.destinatarioPrecargado['apellidos']}',
        'ci': '${widget.destinatarioPrecargado['ci']}',
        'grado': '${widget.destinatarioPrecargado['grado'] ?? '10mo'}',
      });
    }
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    _observacionesController.dispose();
    _tempNombreController.dispose();
    _tempPasswordController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    final meritos = await DatabaseService.getCatalogo('meritos');
    final demeritos = await DatabaseService.getCatalogo('demeritos');
    if (!mounted) return;
    setState(() {
      _catalogoMeritos = meritos;
      _catalogoDemeritos = demeritos;
      _isLoading = false;
    });
  }

  List<dynamic> get _catalogoActual => _tipoActual == 'merito' ? _catalogoMeritos : _catalogoDemeritos;

  void _agregarDestinatario(dynamic est) {
    final id = '${est['id']}';
    if (_destinatarios.any((d) => d['id'] == id)) {
      _showSnackBar('Ya está en la lista', Colors.orange);
      return;
    }
    setState(() {
      _destinatarios.add({
        'id': id,
        'nombre': '${est['nombre']} ${est['apellidos']}',
        'ci': '${est['ci'] ?? ''}',
        'grado': '${est['grado'] ?? '10mo'}',
      });
      _buscarController.clear();
      _resultadosBusqueda = [];
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _buscarEstudiantes(String query) async {
    if (query.length < 2) { setState(() => _resultadosBusqueda = []); return; }
    final resultados = await DatabaseService.buscarEstudiantes(query);
    if (!mounted) return;
    setState(() => _resultadosBusqueda = resultados);
  }

  void _buscarActividades(String query) {
    if (query.length < 1) { setState(() => _resultadosActividad = []); return; }
    final catalogo = _catalogoActual;
    final filtrados = catalogo.where((item) {
      final texto = _tipoActual == 'merito' ? '${item['causa']} ${item['categoria']}'.toLowerCase() : '${item['falta']} ${item['categoria']}'.toLowerCase();
      final coincideCat = _categoriaFiltro == null || item['categoria'] == _categoriaFiltro;
      return texto.contains(query.toLowerCase()) && coincideCat;
    }).toList();
    setState(() => _resultadosActividad = filtrados);
  }

  void _seleccionarActividad(dynamic item) {
    setState(() { _actividadSeleccionada = item; _resultadosActividad = []; });
    if (_tipoActual == 'merito') { _cantidadController.text = '${item['meritos'] ?? 1}'; } else { _actualizarSliders(); }
  }

  void _actualizarSliders() {
    if (_actividadSeleccionada == null || _tipoActual == 'merito') return;
    final grupos = _obtenerGruposPorGrado();
    final hay10mo = grupos['10mo']!.isNotEmpty;
    final hay11_12 = grupos['11no']!.isNotEmpty;
    if (hay10mo && _actividadSeleccionada['demeritos_10mo'] != null) {
      final rango = _parsearRango(_actividadSeleccionada['demeritos_10mo']);
      setState(() { _sliderMin10mo = rango[0]; _sliderMax10mo = rango[1]; _slider10mo = rango[0].toDouble(); });
    }
    if (hay11_12 && _actividadSeleccionada['demeritos_11_12'] != null) {
      final rango = _parsearRango(_actividadSeleccionada['demeritos_11_12']);
      setState(() { _sliderMin11_12 = rango[0]; _sliderMax11_12 = rango[1]; _slider11_12 = rango[0].toDouble(); });
    }
  }

  Map<String, List<String>> _obtenerGruposPorGrado() {
    final grupos = <String, List<String>>{'10mo': [], '11no': []};
    for (final d in _destinatarios) {
      final grado = d['grado'] ?? '10mo';
      if (grado == '10mo') { grupos['10mo']!.add(d['nombre']); } else { grupos['11no']!.add("${d['nombre']} ($grado)"); }
    }
    return grupos;
  }

  List<int> _parsearRango(dynamic str) {
    if (str == null) return [1, 1];
    final parts = str.toString().split('-');
    return [int.tryParse(parts[0]) ?? 1, int.tryParse(parts.length > 1 ? parts[1] : parts[0]) ?? 1];
  }

  void _agregarActividad() {
    if (_actividadSeleccionada == null) { _showSnackBar('Selecciona una actividad', Colors.orange); return; }
    final cantidad = int.tryParse(_cantidadController.text) ?? 1;
    int? v10, v11;
    if (_tipoActual == 'demerito') {
      final grupos = _obtenerGruposPorGrado();
      if (grupos['10mo']!.isNotEmpty) v10 = _slider10mo.toInt();
      if (grupos['11no']!.isNotEmpty) v11 = _slider11_12.toInt();
    }
    setState(() {
      _actividadesAgregadas.add({
        'tipo': _tipoActual, 'categoria': _categoriaFiltro ?? _actividadSeleccionada['categoria'],
        'actividad_id': _actividadSeleccionada['id'],
        'nombre': _tipoActual == 'merito' ? _actividadSeleccionada['causa'] : _actividadSeleccionada['falta'],
        'cantidad': cantidad, 'valor10mo': v10, 'valor11_12': v11,
      });
      _actividadSeleccionada = null; _cantidadController.text = '1';
    });
  }

  Future<void> _enviarNotificacion() async {
    if (_destinatarios.isEmpty || _actividadesAgregadas.isEmpty) return;
    setState(() => _enviando = true);
    final data = {
      'destinatarios': _destinatarios, 'actividades': _actividadesAgregadas,
      'fecha': _fechaController.text, 'hora': _horaController.text,
      'observaciones': _observacionesController.text, 'id_star': _idStar.toString(),
      'tipo_notificador': _tipoNotificador, 'cargo_notificador': _cargoNotificador,
    };
    final response = await DatabaseService.enviarNotificacion(data);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (response['success'] == true) {
      _showSnackBar('Notificación enviada correctamente', Colors.green);
      setState(() { _destinatarios.clear(); _actividadesAgregadas.clear(); _actividadSeleccionada = null; });
      if (_usandoCuentaTemporal) {
        setState(() {
          _usandoCuentaTemporal = false; _idStar = DatabaseService.usuario?.id ?? 0;
          _tipoNotificador = 'cuenta'; _cargoNotificador = DatabaseService.usuario?.cargo ?? '';
          _notificadorNombre = DatabaseService.usuario?.nombreCompleto ?? '';
          _notificadorCargo = DatabaseService.usuario?.cargo ?? '';
        });
      }
    } else {
      _showSnackBar(response['message'] ?? 'Error al enviar', Colors.red);
    }
  }

  Future<void> _verificarCuentaTemporal() async {
    final nombre = _tempNombreController.text.trim();
    final password = _tempPasswordController.text;
    if (nombre.isEmpty || password.isEmpty) { _showSnackBar('Completa todos los campos', Colors.orange); return; }
    final response = await DatabaseService.verificarNotificador(nombre, password);
    if (!mounted) return;
    if (response['success'] == true) {
      setState(() {
        _idStar = response['id']; _tipoNotificador = 'temporal'; _cargoNotificador = response['cargo'];
        _notificadorNombre = response['nombre']; _notificadorCargo = response['cargo'] ?? 'Temporal';
        _usandoCuentaTemporal = true; _tempNombreController.clear(); _tempPasswordController.clear();
      });
      _showSnackBar('Cuenta temporal verificada', Colors.green);
    } else {
      _showSnackBar('Credenciales incorrectas', Colors.red);
    }
  }

  void _mostrarConfirmacion() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Confirmar Notificación', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
            const SizedBox(height: 20),
            Text('Destinatarios (${_destinatarios.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            Wrap(spacing: 8, children: _destinatarios.map((d) => Chip(label: Text('${d['nombre']} (${d['grado']})'), backgroundColor: const Color(0xFFE2E8F0))).toList()),
            const SizedBox(height: 15),
            Text('Actividades (${_actividadesAgregadas.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ...(_actividadesAgregadas.map((a) {
              final grupos = _obtenerGruposPorGrado();
              final hayAmbos = grupos['10mo']!.isNotEmpty && grupos['11no']!.isNotEmpty;
              String valor = a['tipo'] == 'merito' ? '+${a['cantidad']}' : '-${a['cantidad']}';
              if (hayAmbos && a['valor10mo'] != null && a['valor11_12'] != null) valor = '10mo: -${a['valor10mo']} | 11/12: -${a['valor11_12']}';
              return Container(
                margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: a['tipo'] == 'merito' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                child: Text('${a['nombre']} - $valor', style: TextStyle(color: a['tipo'] == 'merito' ? const Color(0xFF065F46) : const Color(0xFF991B1B))),
              );
            })),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); _enviarNotificacion(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)), child: const Text('Confirmar'))),
            ]),
          ],
        ),
      ),
    );
  }

  void _showDialogCuentaTemporal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cuenta Temporal'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _tempNombreController, decoration: const InputDecoration(labelText: 'Nombre y Apellidos', hintText: 'Ej: Juan Perez')),
          const SizedBox(height: 12),
          TextField(controller: _tempPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () { Navigator.pop(context); _verificarCuentaTemporal(); }, child: const Text('Verificar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puedeEnviar = _destinatarios.isNotEmpty && _actividadesAgregadas.isNotEmpty;
    final grupos = _obtenerGruposPorGrado();
    final hay10mo = grupos['10mo']!.isNotEmpty;
    final hay11_12 = grupos['11no']!.isNotEmpty;
    final categorias = <String>{};
    for (final item in _catalogoActual) { categorias.add(item['categoria'] ?? ''); }

    return Scaffold(
      appBar: AppBar(title: const Text('Notificar Actividad'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.people, color: Color(0xFF667EEA)), SizedBox(width: 10), Text('Destinatarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72)))]),
                    const SizedBox(height: 15),
                    if (_destinatarios.isEmpty)
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCBD5E0))), child: const Center(child: Text('No hay destinatarios agregados', style: TextStyle(color: Color(0xFF888888)))))
                    else
                      Wrap(spacing: 8, runSpacing: 8, children: _destinatarios.asMap().entries.map((entry) {
                        final d = entry.value;
                        return Chip(label: Text('${d['nombre']} (${d['ci']}) - ${d['grado']}', style: const TextStyle(color: Colors.white, fontSize: 13)), backgroundColor: const Color(0xFF667EEA), deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white70), onDeleted: () => setState(() => _destinatarios.removeAt(entry.key)));
                      }).toList()),
                    const SizedBox(height: 15),
                    TextField(controller: _buscarController, decoration: InputDecoration(hintText: 'Buscar por CI, ID o nombre...', prefixIcon: const Icon(Icons.search, color: Color(0xFF999999)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))), onChanged: _buscarEstudiantes),
                    if (_resultadosBusqueda.isNotEmpty)
                      Container(margin: const EdgeInsets.only(top: 8), constraints: const BoxConstraints(maxHeight: 250), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 18)]), child: ListView.builder(shrinkWrap: true, itemCount: _resultadosBusqueda.length, itemBuilder: (context, index) {
                        final est = _resultadosBusqueda[index];
                        return ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF667EEA), child: Icon(Icons.person, color: Colors.white)), title: Text('${est['nombre']} ${est['apellidos']}', style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('CI: ${est['ci']} | Grado: ${est['grado'] ?? '10mo'}'), trailing: const Icon(Icons.add_circle, color: Color(0xFF10B981)), onTap: () => _agregarDestinatario(est));
                      })),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EscanerScreen()));
                        if (result != null && mounted) setState(() => _destinatarios.addAll(result as List<Map<String, dynamic>>));
                      },
                      icon: const Icon(Icons.qr_code_scanner), label: const Text('Escanear QR'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E3C72), side: const BorderSide(color: Color(0xFF1E3C72)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    )),
                  ]),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.list_alt, color: Color(0xFF667EEA)), SizedBox(width: 10), Text('Actividades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72)))]),
                    const SizedBox(height: 15),
                    if (_actividadesAgregadas.isEmpty)
                      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCBD5E0))), child: const Center(child: Text('No hay actividades agregadas', style: TextStyle(color: Color(0xFF888888)))))
                    else
                      ...(_actividadesAgregadas.asMap().entries.map((entry) {
                        final act = entry.value;
                        final bg = act['tipo'] == 'merito' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
                        final color = act['tipo'] == 'merito' ? const Color(0xFF065F46) : const Color(0xFF991B1B);
                        return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: color, width: 4))), child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(act['nombre'], style: TextStyle(fontWeight: FontWeight.w600, color: color)), Text(act['categoria'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))])),
                          Text('${act['tipo'] == 'merito' ? "+" : "-"}${act['cantidad']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: color)),
                          const SizedBox(width: 10),
                          GestureDetector(onTap: () => setState(() => _actividadesAgregadas.removeAt(entry.key)), child: const Icon(Icons.delete, color: Color(0xFFEF4444))),
                        ]));
                      })),
                    const SizedBox(height: 15),
                    TextField(decoration: InputDecoration(hintText: 'Buscar mérito o demérito...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))), onChanged: _buscarActividades),
                    if (_resultadosActividad.isNotEmpty)
                      Container(margin: const EdgeInsets.only(top: 8), constraints: const BoxConstraints(maxHeight: 250), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 18)]), child: ListView.builder(shrinkWrap: true, itemCount: _resultadosActividad.length, itemBuilder: (context, index) {
                        final item = _resultadosActividad[index];
                        final nombre = _tipoActual == 'merito' ? item['causa'] : item['falta'];
                        final valor = _tipoActual == 'merito' ? '+${item['meritos']}' : '${item['demeritos_10mo']}/${item['demeritos_11_12']}';
                        return ListTile(title: Text(nombre), subtitle: Text(item['categoria']), trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _tipoActual == 'merito' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)), child: Text(valor, style: TextStyle(fontWeight: FontWeight.w700, color: _tipoActual == 'merito' ? const Color(0xFF065F46) : const Color(0xFF991B1B)))), onTap: () => _seleccionarActividad(item));
                      })),
                  ]),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: GestureDetector(onTap: () => setState(() => _tipoActual = 'merito'), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _tipoActual == 'merito' ? const Color(0xFF10B981) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _tipoActual == 'merito' ? const Color(0xFF10B981) : const Color(0xFFE0E0E0), width: 2)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.emoji_events, color: _tipoActual == 'merito' ? Colors.white : const Color(0xFF10B981)), const SizedBox(width: 8), Text('Mérito', style: TextStyle(fontWeight: FontWeight.w600, color: _tipoActual == 'merito' ? Colors.white : const Color(0xFF10B981)))])))),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(onTap: () => setState(() => _tipoActual = 'demerito'), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _tipoActual == 'demerito' ? const Color(0xFFEF4444) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _tipoActual == 'demerito' ? const Color(0xFFEF4444) : const Color(0xFFE0E0E0), width: 2)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.warning_amber, color: _tipoActual == 'demerito' ? Colors.white : const Color(0xFFEF4444)), const SizedBox(width: 8), Text('Demérito', style: TextStyle(fontWeight: FontWeight.w600, color: _tipoActual == 'demerito' ? Colors.white : const Color(0xFFEF4444)))])))),
                ]),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(value: _categoriaFiltro, decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()), hint: const Text('Todas'), items: [const DropdownMenuItem(value: null, child: Text('Todas')), ...categorias.map((c) => DropdownMenuItem(value: c, child: Text(c)))], onChanged: (v) => setState(() => _categoriaFiltro = v)),
                const SizedBox(height: 15),
                TextField(controller: _cantidadController, decoration: const InputDecoration(labelText: 'Valor', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                if (_tipoActual == 'demerito' && hay10mo && _actividadSeleccionada != null)
                  Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 15, top: 15), decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFC107), width: 2)), child: Column(children: [
                    const Text('Rango 10mo', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF856404))),
                    Slider(min: _sliderMin10mo.toDouble(), max: _sliderMax10mo.toDouble(), value: _slider10mo, onChanged: (v) => setState(() => _slider10mo = v), activeColor: const Color(0xFFD97706)),
                    Text('${_slider10mo.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF856404))),
                  ])),
                if (_tipoActual == 'demerito' && hay11_12 && _actividadSeleccionada != null)
                  Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFC107), width: 2)), child: Column(children: [
                    const Text('Rango 11no/12mo', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF856404))),
                    Slider(min: _sliderMin11_12.toDouble(), max: _sliderMax11_12.toDouble(), value: _slider11_12, onChanged: (v) => setState(() => _slider11_12 = v), activeColor: const Color(0xFFD97706)),
                    Text('${_slider11_12.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF856404))),
                  ])),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _agregarActividad, icon: const Icon(Icons.add), label: const Text('Agregar'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)))),
                const SizedBox(height: 20),
                Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Fecha y Hora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))), const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: TextField(controller: _fechaController, decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder()), readOnly: true, onTap: () async { final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (date != null) _fechaController.text = date.toString().split(' ')[0]; })),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _horaController, decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder()), readOnly: true, onTap: () async { final time = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (time != null) _horaController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'; })),
                  ]),
                ])),
                const SizedBox(height: 20),
                Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Quién Notifica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))), const SizedBox(height: 15),
                  Row(children: [
                    const Icon(Icons.account_circle, size: 42, color: Color(0xFF667EEA)), const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_usandoCuentaTemporal ? 'Cuenta Temporal' : 'Yo (Cuenta actual)', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))), Text(_notificadorNombre, style: const TextStyle(color: Color(0xFF64748B))), Text(_notificadorCargo, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))])),
                    TextButton.icon(onPressed: _showDialogCuentaTemporal, icon: const Icon(Icons.swap_horiz), label: const Text('Cambiar')),
                  ]),
                ])),
                const SizedBox(height: 20),
                Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Observaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))), const SizedBox(height: 12),
                  TextField(controller: _observacionesController, maxLines: 3, decoration: const InputDecoration(hintText: 'Notas adicionales...', border: OutlineInputBorder())),
                ])),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: puedeEnviar ? _mostrarConfirmacion : null,
                    icon: _enviando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                    label: Text(_enviando ? 'Enviando...' : 'Notificar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: puedeEnviar ? const Color(0xFF1E3C72) : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ]),
            ),
    );
  }
}