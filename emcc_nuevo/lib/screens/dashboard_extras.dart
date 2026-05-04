import 'package:flutter/material.dart';

class SemanaAnteriorCard extends StatelessWidget {
  final String fecha;
  final List<dynamic> actividades;
  const SemanaAnteriorCard({super.key, required this.fecha, required this.actividades});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.history, color: Color(0xFF667EEA), size: 22), const SizedBox(width: 8), Text('Semana $fecha', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72)))]),
        const SizedBox(height: 16),
        ...actividades.map((act) {
          final esMerito = act['tipo'] == 'merito';
          return Container(
            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: esMerito ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: esMerito ? const Color(0xFF10B981) : const Color(0xFFEF4444), width: 4))),
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
                ]),
              ])),
            ]),
          );
        }),
      ]),
    );
  }
}

class ModoAlertaBanner extends StatelessWidget {
  final bool activo;
  final Widget child;
  const ModoAlertaBanner({super.key, required this.activo, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!activo) return child;
    return Stack(children: [
      child,
      const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.red), backgroundColor: Colors.red.shade100)),
    ]);
  }
}
