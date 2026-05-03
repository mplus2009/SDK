import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'escaner_screen.dart';
import 'notificar/notificar_variables.dart';
import 'notificar/notificar_destinatarios.dart';
import 'notificar/notificar_actividades.dart';
import 'notificar/notificar_selector.dart';
import 'notificar/notificar_sliders.dart';
import 'notificar/notificar_formulario.dart';

class NotificarScreen extends StatefulWidget {
  final dynamic destinatarioPrecargado;
  const NotificarScreen({super.key, this.destinatarioPrecargado});

  @override
  State<NotificarScreen> createState() => _NotificarScreenState();
}

class _NotificarScreenState extends State<NotificarScreen> {
  final v = NotificarVariables();

  @override
  void initState() {
    super.initState();
    v.fechaController.text = DateTime.now().toString().split(' ')[0];
    v.horaController.text = DateTime.now().toString().substring(11, 16);
    final usuario = DatabaseService.usuario;
    if (usuario != null) {
      v.notificadorNombre = usuario.nombreCompleto;
      v.notificadorCargo = usuario.cargo;
      v.idStar = usuario.id;
      v.cargoNotificador = usuario.cargo;
    }
    if (widget.destinatarioPrecargado != null) {
      v.destinatarios.add({
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
    v.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    v.catalogoMeritos = await DatabaseService.getCatalogo('meritos');
    v.catalogoDemeritos = await DatabaseService.getCatalogo('demeritos');
    if (!mounted) return;
    setState(() => v.isLoading = false);
  }

  List<dynamic> get _catalogoActual => v.tipoActual == 'merito' ? v.catalogoMeritos : v.catalogoDemeritos;

  Map<String, List<String>> _obtenerGruposPorGrado() {
    final grupos = <String, List<String>>{'10mo': [], '11no': []};
    for (final d in v.destinatarios) {
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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  void _agregarDestinatario(dynamic est) {
    final id = '${est['id']}';
    if (v.destinatarios.any((d) => d['id'] == id)) { _showSnackBar('Ya está en la lista', Colors.orange); return; }
    setState(() {
      v.destinatarios.add({'id': id, 'nombre': '${est['nombre']} ${est['apellidos']}', 'ci': '${est['ci'] ?? ''}', 'grado': '${est['grado'] ?? '10mo'}'});
      v.buscarController.clear(); v.resultadosBusqueda = [];
    });
  }

  Future<void> _buscarEstudiantes(String query) async {
    if (query.length < 2) { setState(() => v.resultadosBusqueda = []); return; }
    final resultados = await DatabaseService.buscarEstudiantes(query);
    if (!mounted) return;
    setState(() => v.resultadosBusqueda = resultados);
  }

  void _buscarActividades(String query) {
    if (query.length < 1) { setState(() => v.resultadosActividad = []); return; }
    final filtrados = _catalogoActual.where((item) {
      final texto = v.tipoActual == 'merito' ? '${item['causa']} ${item['categoria']}'.toLowerCase() : '${item['falta']} ${item['categoria']}'.toLowerCase();
      return texto.contains(query.toLowerCase()) && (v.categoriaFiltro == null || item['categoria'] == v.categoriaFiltro);
    }).toList();
    setState(() => v.resultadosActividad = filtrados);
  }

  void _seleccionarActividad(dynamic item) {
    setState(() { v.actividadSeleccionada = item; v.resultadosActividad = []; });
    if (v.tipoActual == 'merito') { v.cantidadController.text = '${item['meritos'] ?? 1}'; } else { _actualizarSliders(); }
  }

  void _actualizarSliders() {
    if (v.actividadSeleccionada == null || v.tipoActual == 'merito') return;
    final grupos = _obtenerGruposPorGrado();
    if (grupos['10mo']!.isNotEmpty && v.actividadSeleccionada['demeritos_10mo'] != null) {
      final rango = _parsearRango(v.actividadSeleccionada['demeritos_10mo']);
      setState(() { v.sliderMin10mo = rango[0]; v.sliderMax10mo = rango[1]; v.slider10mo = rango[0].toDouble(); });
    }
    if (grupos['11no']!.isNotEmpty && v.actividadSeleccionada['demeritos_11_12'] != null) {
      final rango = _parsearRango(v.actividadSeleccionada['demeritos_11_12']);
      setState(() { v.sliderMin11_12 = rango[0]; v.sliderMax11_12 = rango[1]; v.slider11_12 = rango[0].toDouble(); });
    }
  }

  void _agregarActividad() {
    if (v.actividadSeleccionada == null) { _showSnackBar('Selecciona una actividad', Colors.orange); return; }
    final cantidad = int.tryParse(v.cantidadController.text) ?? 1;
    int? v10, v11;
    if (v.tipoActual == 'demerito') {
      final grupos = _obtenerGruposPorGrado();
      if (grupos['10mo']!.isNotEmpty) v10 = v.slider10mo.toInt();
      if (grupos['11no']!.isNotEmpty) v11 = v.slider11_12.toInt();
    }
    setState(() {
      v.actividadesAgregadas.add({
        'tipo': v.tipoActual, 'categoria': v.categoriaFiltro ?? v.actividadSeleccionada['categoria'],
        'actividad_id': v.actividadSeleccionada['id'],
        'nombre': v.tipoActual == 'merito' ? v.actividadSeleccionada['causa'] : v.actividadSeleccionada['falta'],
        'cantidad': cantidad, 'valor10mo': v10, 'valor11_12': v11,
      });
      v.actividadSeleccionada = null; v.cantidadController.text = '1';
    });
  }

  Future<void> _enviarNotificacion() async {
    if (v.destinatarios.isEmpty || v.actividadesAgregadas.isEmpty) return;
    setState(() => v.enviando = true);
    final data = {
      'destinatarios': v.destinatarios, 'actividades': v.actividadesAgregadas,
      'fecha': v.fechaController.text, 'hora': v.horaController.text,
      'observaciones': v.observacionesController.text, 'id_star': v.idStar.toString(),
      'tipo_notificador': v.tipoNotificador, 'cargo_notificador': v.cargoNotificador,
    };
    final response = await DatabaseService.enviarNotificacion(data);
    if (!mounted) return;
    setState(() => v.enviando = false);
    if (response['success'] == true) {
      _showSnackBar('Notificación enviada correctamente', Colors.green);
      setState(() { v.destinatarios.clear(); v.actividadesAgregadas.clear(); v.actividadSeleccionada = null; });
      if (v.usandoCuentaTemporal) {
        setState(() {
          v.usandoCuentaTemporal = false; v.idStar = DatabaseService.usuario?.id ?? 0;
          v.tipoNotificador = 'cuenta'; v.cargoNotificador = DatabaseService.usuario?.cargo ?? '';
          v.notificadorNombre = DatabaseService.usuario?.nombreCompleto ?? '';
          v.notificadorCargo = DatabaseService.usuario?.cargo ?? '';
        });
      }
    } else {
      _showSnackBar(response['message'] ?? 'Error al enviar', Colors.red);
    }
  }

  void _mostrarConfirmacion() {
    final grupos = _obtenerGruposPorGrado();
    final hayAmbos = grupos['10mo']!.isNotEmpty && grupos['11no']!.isNotEmpty;
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
            Text('Destinatarios (${v.destinatarios.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            Wrap(spacing: 8, children: v.destinatarios.map((d) => Chip(label: Text('${d['nombre']} (${d['grado']})'), backgroundColor: const Color(0xFFE2E8F0))).toList()),
            const SizedBox(height: 15),
            Text('Actividades (${v.actividadesAgregadas.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            ...(v.actividadesAgregadas.map((a) {
              String valor = a['tipo'] == 'merito' ? '+${a['cantidad']}' : '-${a['cantidad']}';
              if (hayAmbos && a['valor10mo'] != null && a['valor11_12'] != null) valor = '10mo: -${a['valor10mo']} | 11/12: -${a['valor11_12']}';
              return Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: a['tipo'] == 'merito' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)), child: Text('${a['nombre']} - $valor', style: TextStyle(color: a['tipo'] == 'merito' ? const Color(0xFF065F46) : const Color(0xFF991B1B))));
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
          TextField(controller: v.tempNombreController, decoration: const InputDecoration(labelText: 'Nombre y Apellidos', hintText: 'Ej: Juan Perez')),
          const SizedBox(height: 12),
          TextField(controller: v.tempPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            Navigator.pop(context);
            final nombre = v.tempNombreController.text.trim();
            final password = v.tempPasswordController.text;
            if (nombre.isEmpty || password.isEmpty) { _showSnackBar('Completa todos los campos', Colors.orange); return; }
            final response = await DatabaseService.verificarNotificador(nombre, password);
            if (!mounted) return;
            if (response['success'] == true) {
              setState(() {
                v.idStar = response['id']; v.tipoNotificador = 'temporal'; v.cargoNotificador = response['cargo'];
                v.notificadorNombre = response['nombre']; v.notificadorCargo = response['cargo'] ?? 'Temporal';
                v.usandoCuentaTemporal = true; v.tempNombreController.clear(); v.tempPasswordController.clear();
              });
              _showSnackBar('Cuenta temporal verificada', Colors.green);
            } else {
              _showSnackBar('Credenciales incorrectas', Colors.red);
            }
          }, child: const Text('Verificar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puedeEnviar = v.destinatarios.isNotEmpty && v.actividadesAgregadas.isNotEmpty;
    final grupos = _obtenerGruposPorGrado();
    final categorias = <String>{};
    for (final item in _catalogoActual) { categorias.add(item['categoria'] ?? ''); }

    return Scaffold(
      appBar: AppBar(title: const Text('Notificar Actividad'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: v.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NotificarDestinatarios(
                  v: v,
                  onBuscar: _buscarEstudiantes,
                  onAgregar: _agregarDestinatario,
                  onEscanear: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EscanerScreen()));
                    if (result != null && mounted) setState(() => v.destinatarios.addAll(result as List<Map<String, dynamic>>));
                  },
                  onEliminar: (i) => setState(() => v.destinatarios.removeAt(i)),
                ),
                const SizedBox(height: 20),
                NotificarActividades(
                  v: v,
                  onBuscar: _buscarActividades,
                  onSeleccionar: _seleccionarActividad,
                  onEliminar: (i) => setState(() => v.actividadesAgregadas.removeAt(i)),
                ),
                const SizedBox(height: 20),
                NotificarSelector(v: v, categorias: categorias, onChanged: (val) {
                  if (val == 'merito' || val == 'demerito') {
                    setState(() => v.tipoActual = val);
                  } else {
                    setState(() => v.categoriaFiltro = val.isEmpty ? null : val);
                  }
                }),
                NotificarSliders(
                  v: v,
                  hay10mo: grupos['10mo']!.isNotEmpty,
                  hay11_12: grupos['11no']!.isNotEmpty,
                  onSlider10mo: (val) => setState(() => v.slider10mo = val),
                  onSlider11_12: (val) => setState(() => v.slider11_12 = val),
                ),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _agregarActividad, icon: const Icon(Icons.add), label: const Text('Agregar'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)))),
                NotificarFormulario(v: v, onCambiarNotificador: _showDialogCuentaTemporal, onVerificarTemporal: () {}, onCancelarTemporal: () {}),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: puedeEnviar ? _mostrarConfirmacion : null,
                    icon: v.enviando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                    label: Text(v.enviando ? 'Enviando...' : 'Notificar'),
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
