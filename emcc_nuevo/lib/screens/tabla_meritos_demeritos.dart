import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TablaMeritosDemeritos extends StatefulWidget {
  const TablaMeritosDemeritos({super.key});
  @override
  State<TablaMeritosDemeritos> createState() => _TablaMeritosDemeritosState();
}

class _TablaMeritosDemeritosState extends State<TablaMeritosDemeritos> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _meritos = [];
  List<Map<String, dynamic>> _demeritos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final meritos = await DatabaseService.getCatalogo('meritos');
    final demeritos = await DatabaseService.getCatalogo('demeritos');
    if (!mounted) return;
    setState(() { _meritos = meritos; _demeritos = demeritos; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Méritos y Deméritos'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Méritos'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Deméritos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLista(_meritos, true),
                _buildLista(_demeritos, false),
              ],
            ),
    );
  }

  Widget _buildLista(List<Map<String, dynamic>> items, bool esMerito) {
    final categorias = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final cat = item['categoria'] ?? 'Sin categoría';
      categorias.putIfAbsent(cat, () => []).add(item);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categorias.length,
      itemBuilder: (ctx, i) {
        final cat = categorias.keys.elementAt(i);
        final lista = categorias[cat]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.folder, color: const Color(0xFF667EEA)), const SizedBox(width: 8), Text(cat, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72)))]),
            const SizedBox(height: 12),
            ...lista.map((item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
              child: Row(children: [
                Expanded(child: Text(esMerito ? (item['causa'] ?? '') : (item['falta'] ?? ''), style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: esMerito ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(25)), child: Text(esMerito ? '+${item['meritos']}' : '-${item['demeritos_10mo']}', style: TextStyle(fontWeight: FontWeight.w700, color: esMerito ? const Color(0xFF065F46) : const Color(0xFF991B1B)))),
              ]),
            )),
          ]),
        );
      },
    );
  }
}
