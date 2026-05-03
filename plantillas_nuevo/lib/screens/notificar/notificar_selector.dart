import 'package:flutter/material.dart';
import 'notificar_variables.dart';

class NotificarSelector extends StatelessWidget {
  final NotificarVariables v;
  final Function(String) onChanged;
  final Set<String> categorias;

  const NotificarSelector({
    super.key,
    required this.v,
    required this.onChanged,
    required this.categorias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => onChanged('merito'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: v.tipoActual == 'merito' ? const Color(0xFF10B981) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: v.tipoActual == 'merito' ? const Color(0xFF10B981) : const Color(0xFFE0E0E0), width: 2)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.emoji_events, color: v.tipoActual == 'merito' ? Colors.white : const Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text('Mérito', style: TextStyle(fontWeight: FontWeight.w600, color: v.tipoActual == 'merito' ? Colors.white : const Color(0xFF10B981))),
              ]),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(
            onTap: () => onChanged('demerito'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: v.tipoActual == 'demerito' ? const Color(0xFFEF4444) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: v.tipoActual == 'demerito' ? const Color(0xFFEF4444) : const Color(0xFFE0E0E0), width: 2)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.warning_amber, color: v.tipoActual == 'demerito' ? Colors.white : const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Text('Demérito', style: TextStyle(fontWeight: FontWeight.w600, color: v.tipoActual == 'demerito' ? Colors.white : const Color(0xFFEF4444))),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: v.categoriaFiltro,
          decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
          hint: const Text('Todas'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            ...categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))),
          ],
          onChanged: (val) => onChanged(val ?? ''),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: v.cantidadController,
          decoration: const InputDecoration(labelText: 'Valor', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
      ]),
    );
  }
}
