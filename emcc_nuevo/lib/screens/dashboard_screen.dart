import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/usuario.dart';
import '../config/app_strings.dart';
import 'login_screen.dart';
import 'notificar_screen.dart';
import 'perfil_screen.dart';
import 'escaner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Usuario? _usuario;
  String? _error;
  final TextEditingController _buscarController = TextEditingController();
  List<dynamic> _resultadosBusqueda = [];
  bool _buscando = false;
  bool _mostrarAlarmaToast = true;

  @override
  void initState() {
    super.initState();
    _usuario = DatabaseService.usuario;
    _cargarDashboard();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  Future<void> _cargarDashboard() async {
    setState(() { _isLoading = true; _error = null; });
    final response = await DatabaseService.getDashboard();
    if (!mounted) return;
    if (response['success'] == true) {
      if (response['usuario'] != null) _usuario = Usuario.fromJson(response['usuario']);
      setState(() { _dashboardData = response; _isLoading = false; });
    } else {
      setState(() { _error = response['message'] ?? AppStrings.error; _isLoading = false; });
    }
  }

  Future<void> _buscarEstudiantes(String query) async {
    if (query.length < 2) { setState(() { _resultadosBusqueda = []; _buscando = false; }); return; }
    setState(() => _buscando = true);
    final resultados = await DatabaseService.buscarEstudiantes(query);
    if (!mounted) return;
    setState(() { _resultadosBusqueda = resultados; _buscando = false; });
  }

  Future<void> _logout() async {
    await DatabaseService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _mostrarQR() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text(AppStrings.qrTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25)]), child: const Icon(Icons.qr_code, size: 200, color: Color(0xFF1E3C72))),
          const SizedBox(height: 15),
          Text(_usuario?.nombreCompleto ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E3C72))),
          Text('CI: ${_usuario?.ci ?? ''}', style: const TextStyle(color: Color(0xFF64748B))),
          Text('${AppStrings.roleLabel}: ${_usuario?.cargo ?? ''}', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.download), label: const Text(AppStrings.downloadQR))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(appBar: AppBar(title: const Text(AppStrings.appName)), body: const Center(child: CircularProgressIndicator(color: Color(0xFF1E3C72))));
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text(AppStrings.appName)), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 15), ElevatedButton(onPressed: _cargarDashboard, child: const Text(AppStrings.retry))])));

    final stats = _dashboardData?['stats'] as Map<String, dynamic>?;
    final semanaActual = (_dashboardData?['semana_actual'] as List<dynamic>?) ?? [];
    final esEstudiante = _usuario?.cargo == 'estudiante';
    final puedeNotificar = ['directiva', 'oficial', 'profesor'].contains(_usuario?.cargo) || _usuario?.ocupacion == 'secretaria';
    final alarmaActiva = _dashboardData?['alarma_activa'] == true;
    final nuevasActividades = _dashboardData?['nuevas_actividades'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${_usuario?.nombre ?? AppStrings.appName}'),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code), onPressed: _mostrarQR),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'perfil') Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
              if (v == 'logout') _logout();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'perfil', child: Row(children: [const Icon(Icons.person), const SizedBox(width: 8), const Text(AppStrings.myProfile)])),
              if (nuevasActividades > 0)
                PopupMenuItem(value: 'notif', child: Row(children: [Stack(children: [const Icon(Icons.notifications), Positioned(right: 0, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)), child: Text('$nuevasActividades', style: const TextStyle(color: Colors.white, fontSize: 8))))]), const SizedBox(width: 8), const Text('Notificaciones')])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Color(0xFFEF4444)), const SizedBox(width: 8), const Text(AppStrings.logout, style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _cargarDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (esEstudiante && stats != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    child: Row(children: [
                      _statCard(AppStrings.statMeritsWeek, '${stats['meritos_semana'] ?? 0}', const Color(0xFF10B981), Icons.emoji_events),
                      const SizedBox(width: 8),
                      _statCard(AppStrings.statDemeritsWeek, '${stats['demeritos_semana'] ?? 0}', const Color(0xFFEF4444), Icons.warning_amber),
                      const SizedBox(width: 8),
                      _statCard(AppStrings.statBalanceWeek, '${stats['balance_semana'] ?? 0}', const Color(0xFF1E3C72), Icons.balance),
                    ]),
                  ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Text(AppStrings.welcome, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
                      const Spacer(),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), borderRadius: BorderRadius.circular(25)), child: Text(_usuario?.cargo ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 6),
                    const Text(AppStrings.dashboardPanel, style: TextStyle(color: Color(0xFF555555), fontSize: 14)),
                    const SizedBox(height: 5),
                    Text('${AppStrings.updated}: ${DateTime.now().toString().substring(0, 16)}', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  ]),
                ),
                const SizedBox(height: 18),
                if (alarmaActiva) ...[
                  Container(
                    padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(16), border: const Border(left: BorderSide(color: Color(0xFFFECACA), width: 5))),
                    child: const Row(children: [
                      Icon(Icons.warning, color: Colors.white, size: 24), SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(AppStrings.alarmActive, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        Text(AppStrings.alarmMessage, style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ])),
                    ]),
                  ),
                ],
                if (puedeNotificar) ...[
                  Container(
                    padding: const EdgeInsets.all(18), margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [Icon(Icons.search, color: Color(0xFF667EEA)), SizedBox(width: 8), Text(AppStrings.searchStudent, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72)))]),
                      const SizedBox(height: 5),
                      const Padding(padding: EdgeInsets.only(left: 28), child: Text(AppStrings.searchDesc, style: TextStyle(color: Color(0xFF64748B), fontSize: 14))),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextField(controller: _buscarController, decoration: InputDecoration(hintText: AppStrings.searchHint, prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)), onChanged: _buscarEstudiantes)),
                        const SizedBox(width: 10),
                        ElevatedButton(onPressed: () => _buscarEstudiantes(_buscarController.text), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)), child: const Text(AppStrings.search)),
                      ]),
                      if (_buscando) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
                      if (_resultadosBusqueda.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                          itemCount: _resultadosBusqueda.length,
                          itemBuilder: (ctx, i) {
                            final est = _resultadosBusqueda[i];
                            final balance = (est['meritos'] ?? 0) - (est['demeritos'] ?? 0);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Container(width: 52, height: 52, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), borderRadius: BorderRadius.all(Radius.circular(16))), child: const Icon(Icons.person, color: Colors.white, size: 26)),
                                  const SizedBox(width: 15),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('${est['nombre']} ${est['apellidos']}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                                    Text('CI: ${est['ci']}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                  ])),
                                ]),
                                const SizedBox(height: 10),
                                Row(children: [
                                  _miniStat('${est['meritos'] ?? 0}', AppStrings.meritos, const Color(0xFF10B981)),
                                  const SizedBox(width: 15),
                                  _miniStat('${est['demeritos'] ?? 0}', AppStrings.demeritos, const Color(0xFFEF4444)),
                                  const SizedBox(width: 15),
                                  _miniStat('$balance', AppStrings.balance, const Color(0xFF1E293B)),
                                ]),
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificarScreen(destinatarioPrecargado: est))), icon: const Icon(Icons.add, size: 18), label: const Text(AppStrings.report), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72), padding: const EdgeInsets.symmetric(vertical: 10)))),
                                  const SizedBox(width: 8),
                                  Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.visibility, size: 18), label: const Text(AppStrings.viewProfile), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)))),
                                ]),
                              ]),
                            );
                          },
                        ),
                    ]),
                  ),
                ],
                if (esEstudiante) ...[
                  Container(
                    padding: const EdgeInsets.all(18), margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF667EEA), size: 22), const SizedBox(width: 8),
                        const Text(AppStrings.thisWeek, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
                        const Spacer(),
                        Text(_dashboardData?['semana_fecha'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ]),
                      const SizedBox(height: 16),
                      if (semanaActual.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: Text(AppStrings.noActivities, style: TextStyle(color: Color(0xFF94A3B8)))))
                      else
                        ...semanaActual.map((act) => _actividadItem(act)),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
          if (_mostrarAlarmaToast && alarmaActiva)
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20)]),
                child: Row(children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(child: Text(AppStrings.alarmActive, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _mostrarAlarmaToast = false)),
                ]),
              ),
            ),
        ],
      ),
      floatingActionButton: puedeNotificar ? FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())), icon: const Icon(Icons.add), label: const Text(AppStrings.report), backgroundColor: const Color(0xFF1E3C72)) : null,
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]), borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: const Color(0xFF1E3C72))),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black.withOpacity(0.5))),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E3C72))),
          ]),
        ]),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
    ]);
  }

  Widget _actividadItem(dynamic act) {
    final esMerito = act['tipo'] == 'merito';
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esMerito ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: esMerito ? const Color(0xFF10B981) : const Color(0xFFEF4444), width: 4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: esMerito ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)), child: Icon(esMerito ? Icons.emoji_events : Icons.warning_amber, size: 18, color: esMerito ? const Color(0xFF065F46) : const Color(0xFF991B1B))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(act['falta_causa'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 15)),
          Text(act['categoria'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: esMerito ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)), child: Text('${esMerito ? "+" : "-"}${act['cantidad']}', style: TextStyle(fontWeight: FontWeight.w700, color: esMerito ? const Color(0xFF065F46) : const Color(0xFF991B1B)))),
            const SizedBox(width: 12), Text(act['fecha'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(width: 8), Text(act['hora'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ]),
        ])),
        if (!esMerito && act['alegacion'] == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 30,
              child: ElevatedButton.icon(
                onPressed: () => _alegar(act),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Alegar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
            ),
          ),
      ]),
    );
  }

  void _alegar(dynamic act) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presentar Alegación'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Demérito: ${act['falta_causa'] ?? ""}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: controller, maxLines: 5, decoration: const InputDecoration(hintText: 'Escribe tu alegación...', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          ElevatedButton(
            onPressed: () async {
              final db = await DatabaseService.database;
              await db.update('actividad', {'alegacion': controller.text}, where: 'id = ?', whereArgs: [act['id']]);
              if (mounted) { Navigator.pop(ctx); _cargarDashboard(); }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}

// NOTA: Agrega estos imports al inicio del archivo dashboard_screen.dart:
// import 'tabla_meritos_demeritos.dart';
// import 'mis_notificaciones.dart';
// import 'configuracion.dart';
// import 'horario.dart';
// import 'profesor_horario.dart';
// import 'editar_horario.dart';
// import 'editar_reglas.dart';
// import 'cambiar_cargos.dart';
// import 'cambio_mando.dart';
// import 'panel_secretaria.dart';

// NOTA: Agrega estos imports al inicio del archivo dashboard_screen.dart:
// import 'tabla_meritos_demeritos.dart';
// import 'mis_notificaciones.dart';
// import 'configuracion.dart';
// import 'horario.dart';
// import 'profesor_horario.dart';
// import 'editar_horario.dart';
// import 'editar_reglas.dart';
// import 'cambiar_cargos.dart';
// import 'cambio_mando.dart';
// import 'panel_secretaria.dart';
