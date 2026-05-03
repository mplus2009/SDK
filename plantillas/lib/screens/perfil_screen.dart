import 'package:flutter/material.dart';
import '../services/database_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _perfilData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() { _isLoading = true; _error = null; });
    final response = await DatabaseService.getPerfil();
    if (!mounted) return;
    if (response['success'] == true) {
      setState(() { _perfilData = response; _isLoading = false; });
    } else {
      setState(() { _error = response['message'] ?? 'Error'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = DatabaseService.usuario;
    final perfil = _perfilData?['perfil'] as Map<String, dynamic>?;
    final stats = _perfilData?['stats'] as Map<String, dynamic>?;
    final ultimas = (_perfilData?['ultimas_actividades'] as List<dynamic>?) ?? [];
    final balance = (stats?['meritos'] ?? 0) - (stats?['demeritos'] ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 15), ElevatedButton(onPressed: _cargarPerfil, child: const Text('Reintentar'))]))
              : RefreshIndicator(
                  onRefresh: _cargarPerfil,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                        child: Column(children: [
                          Container(width: 90, height: 90, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), shape: BoxShape.circle), child: const Icon(Icons.person, size: 45, color: Colors.white)),
                          const SizedBox(height: 15),
                          Text('${perfil?['nombre'] ?? usuario?.nombre ?? ''} ${perfil?['apellidos'] ?? usuario?.apellidos ?? ''}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
                          const SizedBox(height: 5),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(20)), child: Text(perfil?['cargo'] ?? usuario?.cargo ?? '', style: const TextStyle(color: Color(0xFF64748B)))),
                          if (usuario?.cargo == 'estudiante') ...[
                            const SizedBox(height: 20),
                            Row(children: [
                              _buildStatBox('${stats?['meritos'] ?? 0}', 'Méritos', const Color(0xFF10B981), Icons.emoji_events),
                              const SizedBox(width: 10),
                              _buildStatBox('${stats?['demeritos'] ?? 0}', 'Deméritos', const Color(0xFFEF4444), Icons.warning_amber),
                              const SizedBox(width: 10),
                              _buildStatBox('$balance', 'Balance', balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), Icons.balance),
                            ]),
                            const SizedBox(height: 15),
                            _buildMensajeEstado(balance),
                          ],
                        ]),
                      ),
                      const SizedBox(height: 20),
                      _buildUltimasActividades(ultimas),
                    ]),
                  ),
                ),
    );
  }

  Widget _buildStatBox(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)), child: Column(children: [
        Icon(icon, size: 28, color: color), const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ])),
    );
  }

  Widget _buildMensajeEstado(int balance) {
    Color bg; IconData icon; String title; String msg;
    if (balance > 0) { bg = const Color(0xFF10B981); icon = Icons.emoji_events; title = '¡Excelente!'; msg = 'Tienes más méritos que deméritos. ¡Sigue así!'; }
    else if (balance < 0) { bg = const Color(0xFFEF4444); icon = Icons.warning_amber; title = 'Atención'; msg = 'Tienes más deméritos que méritos. ¡Esfuérzate más!'; }
    else { bg = const Color(0xFFF59E0B); icon = Icons.balance; title = 'Equilibrado'; msg = 'Tus méritos y deméritos están igualados.'; }
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [bg, bg.withOpacity(0.8)]), borderRadius: BorderRadius.circular(20)), child: Column(children: [Icon(icon, size: 40, color: Colors.white), const SizedBox(height: 10), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)), const SizedBox(height: 5), Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 14))]));
  }

  Widget _buildUltimasActividades(List<dynamic> actividades) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [Icon(Icons.history, color: Color(0xFF667EEA)), SizedBox(width: 8), Text('Últimas Actividades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72)))]),
        const SizedBox(height: 16),
        if (actividades.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay actividades recientes', style: TextStyle(color: Color(0xFF94A3B8)))))
        else
          ...actividades.map((act) {
            final esMerito = act['tipo'] == 'merito';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: esMerito ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(act['falta_causa'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text('${_formatearFecha(act['fecha'])} - ${act['notificador'] ?? 'Sistema'}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ])),
                Text('${esMerito ? "+" : "-"}${act['cantidad']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: esMerito ? const Color(0xFF065F46) : const Color(0xFF991B1B))),
              ]),
            );
          }),
      ]),
    );
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '';
    try { final d = DateTime.parse(fecha.toString()); return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'; } catch (e) { return fecha.toString(); }
  }
}