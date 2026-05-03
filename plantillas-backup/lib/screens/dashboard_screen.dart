// ============================================
// PANTALLA DASHBOARD - PARTE 1
// ============================================

import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/usuario.dart';
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
      if (response['usuario'] != null) {
        _usuario = Usuario.fromJson(response['usuario']);
      }
      setState(() { _dashboardData = response; _isLoading = false; });
    } else {
      setState(() { _error = response['message'] ?? 'Error al cargar'; _isLoading = false; });
    }
  }

  Future<void> _buscarEstudiantes(String query) async {
    if (query.length < 2) {
      setState(() { _resultadosBusqueda = []; _buscando = false; });
      return;
    }
    setState(() => _buscando = true);
    final resultados = await DatabaseService.buscarEstudiantes(query);
    if (!mounted) return;
    setState(() { _resultadosBusqueda = resultados; _buscando = false; });
  }

  Future<void> _logout() async {
    await DatabaseService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  void _mostrarQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => _buildQRModal(),
    );
  }

  Widget _buildQRModal() {
    return Container(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Tu Código QR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25)]),
            child: const Icon(Icons.qr_code, size: 200, color: Color(0xFF1E3C72)),
          ),
          const SizedBox(height: 15),
          Text(_usuario?.nombreCompleto ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E3C72))),
          const SizedBox(height: 10),
          Text('CI: ${_usuario?.ci ?? ''}', style: const TextStyle(color: Color(0xFF64748B))),
          Text('Cargo: ${_usuario?.cargo ?? ''}', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.download), label: const Text('Descargar QR'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(color: Color(0xFF1E3C72)), SizedBox(height: 15), Text('Cargando dashboard...', style: TextStyle(color: Color(0xFF64748B)))]))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 60, color: Colors.red), const SizedBox(height: 15), Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 15), ElevatedButton(onPressed: _cargarDashboard, child: const Text('Reintentar'))]))
              : RefreshIndicator(
                  onRefresh: _cargarDashboard,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true, pinned: true,
                        title: Text('Hola, ${_usuario?.nombre ?? "Usuario"}'),
                        actions: [
                          IconButton(icon: const Icon(Icons.qr_code), onPressed: _mostrarQR),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'logout') _logout();
                              if (value == 'perfil') Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilScreen()));
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'perfil', child: ListTile(leading: Icon(Icons.person), title: Text('Mi Perfil'))),
                              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)))),
                            ],
                          ),
                        ],
                      ),
                      if (_usuario?.cargo == 'estudiante')
                        SliverToBoxAdapter(
                          child: Container(
                            color: const Color(0xFFF0F4F8),
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                            child: Row(children: [
                              _buildStatCard('Mer. Sem', '${_dashboardData?['stats']?['meritos_semana'] ?? 0}', const Color(0xFF10B981), Icons.emoji_events),
                              const SizedBox(width: 8),
                              _buildStatCard('Dem. Sem', '${_dashboardData?['stats']?['demeritos_semana'] ?? 0}', const Color(0xFFEF4444), Icons.warning_amber),
                              const SizedBox(width: 8),
                              _buildStatCard('Bal. Sem', '${_dashboardData?['stats']?['balance_semana'] ?? 0}', const Color(0xFF1E3C72), Icons.balance),
                            ]),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18)]),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Text('👋 Bienvenido!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
                                      const Spacer(),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), borderRadius: BorderRadius.circular(25)), child: Text(_usuario?.cargo ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                                    ]),
                                    const SizedBox(height: 6),
                                    const Text('Panel de control del sistema escolar', style: TextStyle(color: Color(0xFF555555), fontSize: 14)),
                                    const SizedBox(height: 5),
                                    Text('Actualizado: ${DateTime.now().toString().substring(0, 16)}', style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_dashboardData?['alarma_activa'] == true)
                                Container(
                                  padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 18),
                                  decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(16), border: const Border(left: BorderSide(color: Color(0xFFFECACA), width: 5))),
                                  child: const Row(children: [
                                    Icon(Icons.warning, color: Colors.white, size: 24), SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('ALARMA ACTIVADA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                      Text('Has alcanzado el límite de deméritos.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    ])),
                                  ]),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: _usuario?.cargo != 'estudiante'
          ? FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())), icon: const Icon(Icons.add), label: const Text('Notificar'), backgroundColor: const Color(0xFF1E3C72))
          : null,
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]), borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: const Color(0xFF1E3C72))),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black.withOpacity(0.5))),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color == const Color(0xFF1E3C72) ? const Color(0xFF1E3C72) : color)),
          ]),
        ]),
      ),
    );
  }
    Widget _buildMiniStat(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
    ]);
  }

  Widget _buildActividadItem(dynamic act) {
    final esMerito = act['tipo'] == 'merito';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: esMerito ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: esMerito ? const Color(0xFF10B981) : const Color(0xFFEF4444), width: 4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: esMerito ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)), child: Icon(esMerito ? Icons.emoji_events : Icons.warning_amber, size: 18, color: esMerito ? const Color(0xFF065F46) : const Color(0xFF991B1B))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(act['falta_causa'] ?? 'Sin descripción', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 15)),
          Text(act['categoria'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: esMerito ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)), child: Text('${esMerito ? "+" : "-"}${act['cantidad']}', style: TextStyle(fontWeight: FontWeight.w700, color: esMerito ? const Color(0xFF065F46) : const Color(0xFF991B1B)))),
            const SizedBox(width: 12),
            Text(act['fecha'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(width: 8),
            Text(act['hora'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildBuscadorEstudiantes() {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.search, color: Color(0xFF667EEA)), SizedBox(width: 8), Text('Buscar Estudiante', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72)))]),
          const SizedBox(height: 5),
          const Padding(padding: EdgeInsets.only(left: 28), child: Text('Busca por nombre, apellidos o CI', style: TextStyle(color: Color(0xFF64748B), fontSize: 14))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _buscarController,
                decoration: InputDecoration(hintText: 'Ej: Juan Perez o 12345678...', prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                onChanged: _buscarEstudiantes,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: () => _buscarEstudiantes(_buscarController.text), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)), child: const Text('Buscar')),
          ]),
          const SizedBox(height: 12),
          if (_buscando) const Center(child: CircularProgressIndicator()),
          if (_resultadosBusqueda.isNotEmpty)
            SizedBox(
              height: 350,
              child: ListView.builder(
                itemCount: _resultadosBusqueda.length,
                itemBuilder: (context, index) {
                  final est = _resultadosBusqueda[index];
                  final balance = (est['meritos'] ?? 0) - (est['demeritos'] ?? 0);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          _buildMiniStat('${est['meritos'] ?? 0}', 'Méritos', const Color(0xFF10B981)),
                          const SizedBox(width: 15),
                          _buildMiniStat('${est['demeritos'] ?? 0}', 'Deméritos', const Color(0xFFEF4444)),
                          const SizedBox(width: 15),
                          _buildMiniStat('$balance', 'Balance', const Color(0xFF1E293B)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificarScreen(destinatarioPrecargado: est))),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Reportar', style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72), padding: const EdgeInsets.symmetric(vertical: 10)),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPanelProfesorOficial() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
      child: Column(children: [
        Icon(_usuario?.cargo == 'profesor' ? Icons.school : Icons.shield, size: 60, color: const Color(0xFF667EEA)),
        const SizedBox(height: 15),
        Text('Panel de ${_usuario?.cargo ?? ""}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
        const SizedBox(height: 10),
        const Text('Bienvenido al sistema de gestión escolar.', style: TextStyle(color: Color(0xFF64748B))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())), icon: const Icon(Icons.notifications), label: const Text('Notificar Actividad'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
      ]),
    );
  }
}