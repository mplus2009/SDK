import 'package:flutter/material.dart';
import 'notificar_variables.dart';

class NotificarDestinatarios extends StatelessWidget {
  final NotificarVariables v;
  final Function(String) onBuscar;
  final Function(dynamic) onAgregar;
  final VoidCallback onEscanear;
  final Function(int) onEliminar;

  const NotificarDestinatarios({
    super.key,
    required this.v,
    required this.onBuscar,
    required this.onAgregar,
    required this.onEscanear,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.people, color: Color(0xFF667EEA)),
            SizedBox(width: 10),
            Text('Destinatarios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
          ]),
          const SizedBox(height: 15),
          if (v.destinatarios.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCBD5E0))),
              child: const Center(child: Text('No hay destinatarios agregados', style: TextStyle(color: Color(0xFF888888)))),
            )
          else
            Wrap(spacing: 8, runSpacing: 8, children: v.destinatarios.asMap().entries.map((entry) {
              final d = entry.value;
              return Chip(
                label: Text('${d['nombre']} (${d['ci']}) - ${d['grado']}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                backgroundColor: const Color(0xFF667EEA),
                deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white70),
                onDeleted: () => onEliminar(entry.key),
              );
            }).toList()),
          const SizedBox(height: 15),
          TextField(
            controller: v.buscarController,
            decoration: InputDecoration(hintText: 'Buscar por CI, ID o nombre...', prefixIcon: const Icon(Icons.search, color: Color(0xFF999999)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
            onChanged: onBuscar,
          ),
          if (v.resultadosBusqueda.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 18)]),
              child: ListView.builder(shrinkWrap: true, itemCount: v.resultadosBusqueda.length, itemBuilder: (context, index) {
                final est = v.resultadosBusqueda[index];
                return ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF667EEA), child: Icon(Icons.person, color: Colors.white)),
                  title: Text('${est['nombre']} ${est['apellidos']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('CI: ${est['ci']} | Grado: ${est['grado'] ?? '10mo'}'),
                  trailing: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
                  onTap: () => onAgregar(est),
                );
              }),
            ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: onEscanear,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear QR'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E3C72), side: const BorderSide(color: Color(0xFF1E3C72)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          )),
        ],
      ),
    );
  }
}
