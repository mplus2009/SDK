import 'package:flutter/material.dart';
import 'notificar_variables.dart';

class NotificarFormulario extends StatelessWidget {
  final NotificarVariables v;
  final VoidCallback onCambiarNotificador;
  final VoidCallback onVerificarTemporal;
  final VoidCallback onCancelarTemporal;

  const NotificarFormulario({
    super.key,
    required this.v,
    required this.onCambiarNotificador,
    required this.onVerificarTemporal,
    required this.onCancelarTemporal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Fecha y Hora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: TextField(controller: v.fechaController, decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder()), readOnly: true, onTap: () async {
              final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (date != null) v.fechaController.text = date.toString().split(' ')[0];
            })),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: v.horaController, decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder()), readOnly: true, onTap: () async {
              final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (time != null) v.horaController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
            })),
          ]),
        ]),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Quién Notifica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
          const SizedBox(height: 15),
          Row(children: [
            const Icon(Icons.account_circle, size: 42, color: Color(0xFF667EEA)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.usandoCuentaTemporal ? 'Cuenta Temporal' : 'Yo (Cuenta actual)', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              Text(v.notificadorNombre, style: const TextStyle(color: Color(0xFF64748B))),
              Text(v.notificadorCargo, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ])),
            TextButton.icon(onPressed: onCambiarNotificador, icon: const Icon(Icons.swap_horiz), label: const Text('Cambiar')),
          ]),
        ]),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Observaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
          const SizedBox(height: 12),
          TextField(controller: v.observacionesController, maxLines: 3, decoration: const InputDecoration(hintText: 'Notas adicionales...', border: OutlineInputBorder())),
        ]),
      ),
    ]);
  }
}
