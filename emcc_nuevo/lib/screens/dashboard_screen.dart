import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/database_service.dart';
import '../services/mesh_service.dart';
import '../models/usuario.dart';
import 'login_screen.dart';
import 'notificar_screen.dart';
import 'perfil_screen.dart';
import 'tabla_meritos_demeritos.dart';
import 'mis_notificaciones.dart';
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
  bool _searching = false;
  final _mesh = MeshService();
  MeshStatus _meshStatus = MeshStatus.disconnected;
  List<Map<String, String>> _foundDevices = [];

  @override
  void initState() {
    super.initState();
    _load();
    _mesh.statusStream.listen((s) => setState(() { _meshStatus = s; if (s == MeshStatus.connected) _foundDevices = _mesh.foundDevices; }));
  }

  @override
  void dispose() { _bc.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await DatabaseService.getDashboard();
    if (!mounted) return;
    setState(() { _data = r; _loading = false; });
    _mesh.searchDevices();
  }

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    _results = await DatabaseService.buscarEstudiantes(q);
    setState(() => _searching = false);
  }

  Future<void> _logout() async {
    await DatabaseService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _go(String r) {
    Widget page;
    switch (r) {
      case 'perfil': page = const PerfilScreen(); break;
      case 'notif': page = const MisNotificaciones(); break;
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

  void _mostrarQR() {
    final u = DatabaseService.usuario;
    if (u == null) return;
    final qrData = '${u.id}|${u.nombre}|${u.apellidos}|${u.ci}|${u.cargo}';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Mi Código QR', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1E3C72))),
          const SizedBox(height: 20),
          QrImageView(data: qrData, version: QrVersions.auto, size: 200),
          const SizedBox(height: 20),
          Text(u.nombreCompleto, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('CI: ${u.ci}  |  ${u.cargo}', style: GoogleFonts.poppins(color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildMeshIndicator() {
    IconData icon; Color color; String label;
    switch (_meshStatus) {
      case MeshStatus.disconnected: icon = Icons.signal_wifi_off; color = Colors.grey; label = 'Sin red'; break;
      case MeshStatus.searching: icon = Icons.wifi_find; color = Colors.orange; label = 'Buscando...'; break;
      case MeshStatus.connected: icon = Icons.signal_wifi_4_bar; color = Colors.green; label = '${_foundDevices.length} disp.'; break;
      case MeshStatus.serverOn: icon = Icons.wifi_tethering; color = Colors.teal; label = "Servidor ON"; break;
      case MeshStatus.sending: icon = Icons.signal_wifi_statusbar_4_bar; color = Colors.blue; label = 'Enviando...'; break;
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _showMeshInfo(),
        child: Chip(avatar: Icon(icon, size: 18, color: color), label: Text(label, style: const TextStyle(fontSize: 11)), backgroundColor: color.withOpacity(0.1)),
      ),
    );
  }

  void _showMeshInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🌐 Red Mesh'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Estado: ${_meshStatus.name}'),
          const SizedBox(height: 10),
          const Text('Dispositivos encontrados:'),
          ..._foundDevices.map((d) => ListTile(leading: const Icon(Icons.phone_android), title: Text(d["name"] ?? d["ip"] ?? ""), dense: true)),
          if (_foundDevices.isEmpty) const Text('Ninguno'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuItems(Usuario u, int n) => [
    PopupMenuItem(value: 'perfil', child: Row(children: [Icon(Icons.person_2, color: Colors.blue.shade700), const SizedBox(width: 10), const Text('Mi Perfil')])),
    if (n > 0) PopupMenuItem(value: 'notif', child: Row(children: [Icon(Icons.notifications_active, color: Colors.red), const SizedBox(width: 10), Text('Notificaciones ($n)')])),
    PopupMenuItem(value: 'tabla', child: Row(children: [Icon(Icons.table_chart, color: Colors.purple.shade700), const SizedBox(width: 10), const Text('Tabla Méritos/Deméritos')])),
    if (u.cargo == 'profesor') PopupMenuItem(value: 'prof_h', child: Row(children: [Icon(Icons.book, color: Colors.teal), const SizedBox(width: 10), const Text('Mi Horario')])),
    PopupMenuItem(value: 'horario', child: Row(children: [Icon(Icons.calendar_month, color: Colors.orange), const SizedBox(width: 10), const Text('Horario')])),
    if (u.cargo == 'directiva') ...[
      PopupMenuItem(value: 'edit_h', child: Row(children: [Icon(Icons.edit_calendar, color: Colors.indigo), const SizedBox(width: 10), const Text('Editar Horario')])),
      PopupMenuItem(value: 'edit_r', child: Row(children: [Icon(Icons.gavel, color: Colors.red.shade700), const SizedBox(width: 10), const Text('Editar Reglas')])),
      PopupMenuItem(value: 'cargos', child: Row(children: [Icon(Icons.swap_horiz, color: Colors.brown), const SizedBox(width: 10), const Text('Cambiar Cargos')])),
    ],
    if (u.cargo == 'oficial') PopupMenuItem(value: 'mando', child: Row(children: [Icon(Icons.military_tech, color: Colors.amber.shade800), const SizedBox(width: 10), const Text('Cambio de Mando')])),
    if (u.cargo == 'directiva' || u.ocupacion == 'secretaria') PopupMenuItem(value: 'secre', child: Row(children: [Icon(Icons.admin_panel_settings, color: Colors.pink), const SizedBox(width: 10), const Text('Panel Secretaria')])),
    PopupMenuItem(value: 'config', child: Row(children: [Icon(Icons.settings, color: Colors.grey.shade700), const SizedBox(width: 10), const Text('Configuración')])),
    PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), const SizedBox(width: 10), const Text('Cerrar Sesión')])),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final u = DatabaseService.usuario!;
    final stats = _data?['stats'] as Map<String, dynamic>? ?? {};
    final semana = (_data?['semana_actual'] as List<dynamic>?) ?? [];
    final esEst = u.cargo == 'estudiante';
    final puede = ['directiva', 'oficial', 'profesor'].contains(u.cargo) || u.ocupacion == 'secretaria';
    final alarma = _data?['alarma_activa'] == true;
    final nuevas = _data?['nuevas_actividades'] as int? ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Hola, ${u.nombre}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [_buildMeshIndicator(), IconButton(icon: const Icon(Icons.qr_code_2), onPressed: _mostrarQR), PopupMenuButton<String>(onSelected: (v) => v == 'logout' ? _logout() : _go(v), itemBuilder: (_) => _menuItems(u, nuevas))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (esEst) _buildStats(stats).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          _buildWelcome(u).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          if (alarma) _buildAlarmaBanner().animate().shake(),
          if (puede) ...[const SizedBox(height: 20), _buildBuscador().animate().fadeIn(delay: 300.ms)],
          if (esEst && semana.isNotEmpty) ...[const SizedBox(height: 20), _buildSemana(semana).animate().fadeIn(delay: 400.ms)],
          if (['profesor', 'oficial'].contains(u.cargo)) ...[const SizedBox(height: 20), _buildPanelCargo(u).animate().fadeIn(delay: 300.ms)],
        ]),
      ),
      floatingActionButton: puede ? FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())), icon: const Icon(Icons.edit_note), label: const Text('Notificar'), backgroundColor: const Color(0xFF1E3C72)) : null,
    );
  }

  Widget _buildStats(Map<String, dynamic> s) => Row(children: [
    _stat('Mer. Sem', '${s['meritos_semana']??0}', const Color(0xFF10B981), Icons.star),
    const SizedBox(width: 12),
    _stat('Dem. Sem', '${s['demeritos_semana']??0}', const Color(0xFFEF4444), Icons.warning),
    const SizedBox(width: 12),
    _stat('Bal. Sem', '${s['balance_semana']??0}', const Color(0xFF3B82F6), Icons.account_balance),
  ]);

  Widget _stat(String l, String v, Color c, IconData i) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: c.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: [Icon(i, color: c, size: 28), const SizedBox(height: 8), Text(v, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: c)), Text(l, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey))])));

  Widget _buildWelcome(Usuario u) => Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF1E3C72).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bienvenido de vuelta', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)), const SizedBox(height: 4), Text(u.nombreCompleto, style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)), const SizedBox(height: 10), Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text(u.cargo.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))), const Spacer(), Text('Actualizado: ${DateTime.now().toString().substring(0,16)}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10))])]));

  Widget _buildAlarmaBanner() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3))), child: const Row(children: [Icon(Icons.warning_amber, color: Color(0xFFEF4444)), SizedBox(width: 12), Expanded(child: Text('Has alcanzado el límite de deméritos', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500)))]));

  Widget _buildBuscador() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Buscar Estudiante', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 12), TextField(controller: _bc, decoration: InputDecoration(hintText: 'Nombre, apellidos o CI...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), filled: true, fillColor: const Color(0xFFF5F7FA)), onChanged: _search), if (_searching) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())), ..._results.map((e) => Container(margin: const EdgeInsets.only(top: 10), decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16)), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFF1E3C72), child: Text('${e['nombre']?[0] ?? ''}', style: const TextStyle(color: Colors.white))), title: Text('${e['nombre']} ${e['apellidos']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), subtitle: Text('CI: ${e['CI']}'), trailing: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificarScreen(destinatarioPrecargado: e))), child: const Text('Reportar')))))]));

  Widget _buildSemana(List<dynamic> s) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Esta Semana', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 12), ...s.map((a) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: a['tipo']=='merito'?const Color(0xFFD1FAE5):const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(a['tipo']=='merito'?Icons.star:Icons.warning, color: a['tipo']=='merito'?const Color(0xFF065F46):const Color(0xFF991B1B)), const SizedBox(width: 12), Expanded(child: Text(a['falta_causa']??'', style: GoogleFonts.poppins(fontWeight: FontWeight.w500))), Text('${a['cantidad']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: a['tipo']=='merito'?const Color(0xFF065F46):const Color(0xFF991B1B)))])))]));

  Widget _buildPanelCargo(Usuario u) { return Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(children: [Icon(u.cargo=="profesor"?Icons.school:Icons.shield, size: 60, color: const Color(0xFF1E3C72)), const SizedBox(height: 15), Text("Panel de ${u.cargo}", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 20), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())), icon: const Icon(Icons.edit_note), label: const Text("Notificar Actividad")))])); }
}
