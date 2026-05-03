import 'package:flutter/material.dart';
import 'notificar_variables.dart';

class NotificarSliders extends StatelessWidget {
  final NotificarVariables v;
  final bool hay10mo;
  final bool hay11_12;
  final Function(double) onSlider10mo;
  final Function(double) onSlider11_12;

  const NotificarSliders({
    super.key,
    required this.v,
    required this.hay10mo,
    required this.hay11_12,
    required this.onSlider10mo,
    required this.onSlider11_12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (v.tipoActual == 'demerito' && hay10mo && v.actividadSeleccionada != null)
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFC107), width: 2)),
          child: Column(children: [
            const Text('Rango 10mo', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF856404))),
            Slider(min: v.sliderMin10mo.toDouble(), max: v.sliderMax10mo.toDouble(), value: v.slider10mo, onChanged: onSlider10mo, activeColor: const Color(0xFFD97706)),
            Text('${v.slider10mo.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF856404))),
          ]),
        ),
      if (v.tipoActual == 'demerito' && hay11_12 && v.actividadSeleccionada != null)
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(color: const Color(0xFFFFF3CD), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFC107), width: 2)),
          child: Column(children: [
            const Text('Rango 11no/12mo', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF856404))),
            Slider(min: v.sliderMin11_12.toDouble(), max: v.sliderMax11_12.toDouble(), value: v.slider11_12, onChanged: onSlider11_12, activeColor: const Color(0xFFD97706)),
            Text('${v.slider11_12.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF856404))),
          ]),
        ),
    ]);
  }
}
