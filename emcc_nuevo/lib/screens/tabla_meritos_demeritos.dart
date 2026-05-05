import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TablaMeritosDemeritos extends StatefulWidget {
  const TablaMeritosDemeritos({super.key});
  @override
  State<TablaMeritosDemeritos> createState() => _TablaMeritosDemeritosState();
}

class _TablaMeritosDemeritosState extends State<TablaMeritosDemeritos> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _meritos = [];
  List<Map<String, dynamic>> _demeritos = [];
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    _meritos = await DatabaseService.getCatalogo('meritos');
    _demeritos = await DatabaseService.getCatalogo('demeritos');
    setState(() {});
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> list, bool esMerito) {
    if (_query.isEmpty) return list;
    return list.where((item) {
      final text = esMerito ? '${item['causa']} ${item['categoria']}' : '${item['falta']} ${item['categoria']}';
      return text.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Méritos y Deméritos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white54, indicatorColor: Colors.white, tabs: const [Tab(icon: Icon(Icons.star), text: 'Méritos'), Tab(icon: Icon(Icons.warning), text: 'Deméritos')]),
          ]),
        ),
      ),
      body: TabBarView(controller: _tab, children: [_buildList(_filter(_meritos, true), true), _buildList(_filter(_demeritos, false), false)]),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool esMerito) {
    final cats = <String, List<Map<String, dynamic>>>{};
    for (final i in items) { cats.putIfAbsent(i['categoria'] ?? '', () => []).add(i); }
    if (cats.isEmpty) return const Center(child: Text('Sin resultados'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      itemBuilder: (_, i) {
        final cat = cats.keys.elementAt(i);
        final list = cats[cat]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.folder, color: const Color(0xFF667EEA)), const SizedBox(width: 8), Text(cat, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72)))]),
            const SizedBox(height: 12),
            ...list.map((item) => Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
              child: Row(children: [
                Expanded(child: Text(esMerito ? '${item['causa']}' : '${item['falta']}', style: const TextStyle(fontSize: 14))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: esMerito ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)), child: Text(esMerito ? '+${item['meritos']}' : '-${item['demeritos_10mo']}', style: TextStyle(fontWeight: FontWeight.w700, color: esMerito ? const Color(0xFF065F46) : const Color(0xFF991B1B)))),
              ]),
            )),
          ]),
        );
      },
    );
  }
}
