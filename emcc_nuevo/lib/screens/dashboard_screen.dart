import 'package:flutter/material.dart';
import '../services/database_service.dart';
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
  bool _alarmaToast = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _bc.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await DatabaseService.getDashboard();
    if (!mounted) return;
    setState(() { _data = r; _loading = false; });
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
      appBar: AppBar(title: Text('Hola, ${u?.nombre ?? ""}'), actions: [
        IconButton(icon: const Icon(Icons.qr_code), onPressed: () => showModalBottomSheet(context: context, builder: (_) => Container(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Tu Código QR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 20), const Icon(Icons.qr_code, size: 200), Text(u?.nombreCompleto??'')])))),
        PopupMenuButton<String>(onSelected: (v) => v == 'logout' ? _logout() : _go(v), itemBuilder: (_) => [
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
          if (u?.cargo == 'directiva' || u?.ocupacion == 'secretaria') const PopupMenuItem(value: 'secre', child: Text('📝 Panel Secretaria')),
          const PopupMenuItem(value: 'config', child: Text('⚙️ Configuración')),
          const PopupMenuItem(value: 'logout', child: Text('🚪 Cerrar Sesión')),
        ]),
      ]),
      body: Stack(children: [
        RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(14), children: [
          if (esEst) Row(children: [_st('Mer. Sem', '${stats?['meritos_semana']??0}', Colors.green), const SizedBox(width: 8), _st('Dem. Sem', '${stats?['demeritos_semana']??0}', Colors.red), const SizedBox(width: 8), _st('Bal. Sem', '${stats?['balance_semana']??0}', Colors.blue)]),
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('👋 Bienvenido!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))), Text('Panel de control - ${u?.cargo ?? ""}', style: const TextStyle(color: Colors.grey)), Text('Actualizado: ${DateTime.now().toString().substring(0,16)}', style: const TextStyle(fontSize: 11, color: Colors.grey))])),
          if (alarma) ...[const SizedBox(height: 18), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.warning, color: Colors.white), SizedBox(width: 12), Expanded(child: Text('ALARMA ACTIVADA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))]))],
          if (puede) ...[const SizedBox(height: 18), Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [const Text('Buscar Estudiante', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), TextField(controller: _bc, decoration: const InputDecoration(hintText: 'Nombre, apellidos o CI...', prefixIcon: Icon(Icons.search)), onChanged: _search), if (_searching) const CircularProgressIndicator(), ..._results.map((e) => ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text('${e['nombre']} ${e['apellidos']}'), subtitle: Text('CI: ${e['CI']}'), trailing: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificarScreen(destinatarioPrecargado: e))), child: const Text('Reportar'))))]))],
          if (esEst && semana.isNotEmpty) ...[const SizedBox(height: 18), Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Esta Semana', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), ...semana.map((a) => ListTile(leading: Icon(a['tipo']=='merito'?Icons.star:Icons.warning, color: a['tipo']=='merito'?Colors.green:Colors.red), title: Text(a['falta_causa']??''), subtitle: Text('${a['fecha']} - ${a['cantidad']}')))]))],
          if (['profesor', 'oficial'].contains(u?.cargo)) ...[const SizedBox(height: 18), Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(children: [Icon(u?.cargo=='profesor'?Icons.school:Icons.shield, size: 60), const SizedBox(height: 15), Text('Panel de ${u?.cargo??""}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 20), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())), icon: const Icon(Icons.notifications), label: const Text('Notificar Actividad')))]))],
        ])),
        if (_alarmaToast && alarma) Positioned(bottom: 20, left: 20, right: 20, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.warning, color: Colors.white), const SizedBox(width: 12), const Expanded(child: Text('ALARMA ACTIVADA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))), IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _alarmaToast = false))]))),
      ]),
      floatingActionButton: puede ? FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())), icon: const Icon(Icons.add), label: const Text('Notificar'), backgroundColor: const Color(0xFF1E3C72)) : null,
    );
  }

  Widget _st(String l, String v, Color c) => Expanded(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Column(children: [Text(l, style: TextStyle(fontSize: 10, color: c)), Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c))])));
}
