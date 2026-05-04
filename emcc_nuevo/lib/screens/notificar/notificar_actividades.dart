import 'package:flutter/material.dart';
import 'notificar_variables.dart';

class NotificarActividades extends StatelessWidget {
  final NotificarVariables v;
  final Function(String) onBuscar;
  final Function(dynamic) onSeleccionar;
  final Function(int) onEliminar;

  const NotificarActividades({
    super.key,
    required this.v,
    required this.onBuscar,
    required this.onSeleccionar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.list_alt, color: Color(0xFF667EEA)), SizedBox(width: 10),
          Text('Actividades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
        ]),
        const SizedBox(height: 15),
        if (v.actividadesAgregadas.isEmpty)
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCBD5E0))), child: const Center(child: Text('No hay actividades agregadas', style: TextStyle(color: Color(0xFF888888)))))
        else
          ...(v.actividadesAgregadas.asMap().entries.map((entry) {
            final act = entry.value;
            final bg = act['tipo'] == 'merito' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
            final color = act['tipo'] == 'merito' ? const Color(0xFF065F46) : const Color(0xFF991B1B);
            return Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: color, width: 4))),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(act['nombre'], style: TextStyle(fontWeight: FontWeight.w600, color: color)), Text(act['categoria'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))])),
                Text('${act['tipo'] == 'merito' ? "+" : "-"}${act['cantidad']}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: color)),
                const SizedBox(width: 10),
                GestureDetector(onTap: () => onEliminar(entry.key), child: const Icon(Icons.delete, color: Color(0xFFEF4444))),
              ]),
            );
          })),
        const SizedBox(height: 15),
        TextField(decoration: InputDecoration(hintText: 'Buscar mérito o demérito...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))), onChanged: onBuscar),
        if (v.resultadosActividad.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8), constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 18)]),
            child: ListView.builder(shrinkWrap: true, itemCount: v.resultadosActividad.length, itemBuilder: (context, index) {
              final item = v.resultadosActividad[index];
              final nombre = v.tipoActual == 'merito' ? item['causa'] : item['falta'];
              final valor = v.tipoActual == 'merito' ? '+${item['meritos']}' : '${item['demeritos_10mo']}/${item['demeritos_11_12']}';
              return ListTile(
                title: Text(nombre), subtitle: Text(item['categoria']),
                trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: v.tipoActual == 'merito' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)), child: Text(valor, style: TextStyle(fontWeight: FontWeight.w700, color: v.tipoActual == 'merito' ? const Color(0xFF065F46) : const Color(0xFF991B1B)))),
                onTap: () => onSeleccionar(item),
              );
            }),
          ),
      ]),
    );
  }
}
