import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/mesh_service.dart';
import '../models/usuario.dart';
import 'login_screen.dart';
import 'notificar_screen.dart';
import 'perfil_screen.dart';
import 'tabla_meritos_demeritos.dart';
import 'configuracion.dart';
import 'horario.dart';
import 'profesor_horario.dart';
import 'editar_horario.dart';
import 'editar_reglas.dart';
import 'cambiar_cargos.dart';
import 'cambio_mando.dart';
import 'panel_secretaria.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  final _bc = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _alarmaToast = true;

  @override
  void initState() {
    super.initState();
    _load();
    MeshService.start(); // Iniciar red mesh
  }

  @override
  void dispose() {
    _bc.dispose();
    MeshService.stop(); // Detener mesh
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await DatabaseService.getDashboard();
    if (!mounted) return;
    setState(() { _data = r; _loading = false; });
  }

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    final r = await DatabaseService.buscarEstudiantes(q);
    setState(() => _results = r);
  }

  void _go(String r) {
    Widget page;
    switch (r) {
      case 'perfil': page = const PerfilScreen(); break;
      case 'tabla': page = const TablaMeritosDemeritos(); break;
      case 'horario': page = const HorarioScreen(); break;
      case 'prof_h': page = const ProfesorHorario(); break;
      case 'edit_h': page = const EditarHorario(); break;
      case 'edit_r': page = const EditarReglas(); break;
      case 'cargos': page = const CambiarCargos(); break;
      case 'mando': page = const CambioMando(); break;
      case 'secre': page = const PanelSecretaria(); break;
      case 'config': page = const ConfiguracionScreen(); break;
      default: return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final u = DatabaseService.usuario;
    final stats = _data?['stats'] as Map<String, dynamic>?;
    final semana = (_data?['semana_actual'] as List<dynamic>?) ?? [];
    final esEst = u?.cargo == 'estudiante';
    final puede = ['directiva', 'oficial', 'profesor'].contains(u?.cargo) || u?.ocupacion == 'secretaria';
    final alarma = _data?['alarma_activa'] == true;
    final nuevas = _data?['nuevas_actividades'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${u?.nombre ?? ""}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => v == 'logout'
                ? DatabaseService.logout().then((_) =>
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())))
                : _go(v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'perfil', child: Text('👤 Mi Perfil')),
              if (nuevas > 0) PopupMenuItem(value: 'notif', child: Text('🔔 Notificaciones ($nuevas)')),
              const PopupMenuItem(value: 'tabla', child: Text('📋 Tabla Méritos/Deméritos')),
              if (u?.cargo == 'profesor') const PopupMenuItem(value: 'prof_h', child: Text('📚 Mi Horario')),
              const PopupMenuItem(value: 'horario', child: Text('📅 Horario')),
              if (u?.cargo == 'directiva') ...[
                const PopupMenuItem(value: 'edit_h', child: Text('✏️ Editar Horario')),
                const PopupMenuItem(value: 'edit_r', child: Text('⚙️ Editar Reglas')),
                const PopupMenuItem(value: 'cargos', child: Text('🔄 Cambiar Cargos')),
              ],
              if (u?.cargo == 'oficial') const PopupMenuItem(value: 'mando', child: Text('🎖️ Cambio de Mando')),
              if (u?.cargo == 'directiva' || u?.ocupacion == 'secretaria')
                const PopupMenuItem(value: 'secre', child: Text('📝 Panel Secretaria')),
              const PopupMenuItem(value: 'config', child: Text('⚙️ Configuración')),
              const PopupMenuItem(value: 'logout', child: Text('🚪 Cerrar Sesión')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            if (esEst)
              Row(children: [
                _st('Mer. Sem', '${stats?['meritos_semana'] ?? 0}', Colors.green),
                const SizedBox(width: 8),
                _st('Dem. Sem', '${stats?['demeritos_semana'] ?? 0}', Colors.red),
                const SizedBox(width: 8),
                _st('Bal. Sem', '${stats?['balance_semana'] ?? 0}', Colors.blue),
              ]),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('👋 Bienvenido!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
                Text('Panel de control - ${u?.cargo ?? ""}', style: const TextStyle(color: Colors.grey)),
                Text('Actualizado: ${DateTime.now().toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
            if (alarma) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                child: const Row(children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('ALARMA ACTIVADA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                ]),
              ),
            ],
            if (puede) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  const Text('Buscar Estudiante', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  TextField(
                    controller: _bc,
                    decoration: const InputDecoration(hintText: 'Nombre, apellidos o CI...', prefixIcon: Icon(Icons.search)),
                    onChanged: _search,
                  ),
                  ..._results.map((e) => Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18)),
                        child: Column(children: [
                          Row(children: [
                            Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                                    borderRadius: BorderRadius.all(Radius.circular(16))),
                                child: const Icon(Icons.person, color: Colors.white)),
                            const SizedBox(width: 15),
                            Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${e['nombre']} ${e['apellidos']}',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              Text('CI: ${e['CI']}',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                            ])),
                            ElevatedButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => NotificarScreen(destinatarioPrecargado: e))),
                                child: const Text('Reportar')),
                          ])
                        ]),
                      )),
                ]),
              ),
            ],
            if (esEst && semana.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Esta Semana', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...semana.map((a) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: a['tipo'] == 'merito'
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border(
                                left: BorderSide(
                                    color: a['tipo'] == 'merito' ? Colors.green : Colors.red, width: 4))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a['falta_causa'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Notificado por: ${a['notificador'] ?? 'Sistema'}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          Text('${a['fecha']} - ${a['hora']?.toString().substring(0, 5) ?? ""}',
                              style: const TextStyle(fontSize: 11)),
                          Align(
                              alignment: Alignment.centerRight,
                              child: Text('${a['tipo'] == 'merito' ? "+" : "-"}${a['cantidad']}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: a['tipo'] == 'merito' ? Colors.green : Colors.red))),
                        ]),
                      )),
                ]),
              ),
            ],
            if (['profesor', 'oficial'].contains(u?.cargo)) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(children: [
                  Icon(u?.cargo == 'profesor' ? Icons.school : Icons.shield, size: 60),
                  const SizedBox(height: 15),
                  Text('Panel de ${u?.cargo ?? ""}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())),
                      icon: const Icon(Icons.notifications),
                      label: const Text('Notificar Actividad')),
                ]),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: puede
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Notificar'),
              backgroundColor: const Color(0xFF1E3C72),
            )
          : null,
    );
  }

  Widget _st(String l, String v, Color c) => Expanded(
        child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(l, style: TextStyle(fontSize: 10, color: c)),
              Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
            ])),
      );
}
