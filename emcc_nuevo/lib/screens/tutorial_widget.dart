import 'package:flutter/material.dart';

class TutorialWidget extends StatefulWidget {
  final VoidCallback onFinish;
  final bool esEstudiante;
  const TutorialWidget({super.key, required this.onFinish, required this.esEstudiante});

  @override
  State<TutorialWidget> createState() => _TutorialWidgetState();
}

class _TutorialWidgetState extends State<TutorialWidget> {
  int _step = 1;
  final int _totalSteps = 5;

  @override
  Widget build(BuildContext context) {
    final steps = widget.esEstudiante
        ? ['Tu Código QR', 'Notificar Actividades', 'Menú de Usuario', 'Tus Estadísticas', 'Actividades de la Semana']
        : ['Tu Código QR', 'Notificar Actividades', 'Menú de Usuario', 'Buscador de Estudiantes', 'Panel de Control'];
    
    final icons = [Icons.qr_code, Icons.notifications, Icons.person, Icons.bar_chart, Icons.calendar_today];
    final descriptions = widget.esEstudiante
        ? ['Toca el botón QR para ver tu código personal.', 'Usa el botón Notificar para registrar méritos o deméritos.', 'Toca tu avatar para acceder a Mi Perfil y más.', 'Aquí verás tu acumulado de Méritos, Deméritos y Balance.', 'Aquí aparecen todos los méritos y deméritos recibidos.']
        : ['Toca el botón QR para ver tu código personal.', 'Usa el botón Notificar para registrar méritos o deméritos.', 'Toca tu avatar para acceder a Mi Perfil y más.', 'Busca estudiantes por nombre, apellidos o CI.', 'Gestiona el sistema desde tu panel de control.'];

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(30),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 70, height: 70, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), borderRadius: BorderRadius.circular(25)), child: Icon(icons[_step-1], size: 36, color: Colors.white)),
            const SizedBox(height: 20),
            Text(steps[_step-1], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
            const SizedBox(height: 10),
            Text(descriptions[_step-1], textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)),
            const SizedBox(height: 25),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_totalSteps, (i) => Container(width: _step == i+1 ? 25 : 10, height: 10, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: _step == i+1 ? const Color(0xFF1E3C72) : const Color(0xFFCBD5E1))))),
            const SizedBox(height: 20),
            Row(children: [
              TextButton(onPressed: _step > 1 ? () => setState(() => _step--) : null, child: const Text('Anterior')),
              const Spacer(),
              TextButton(onPressed: widget.onFinish, child: const Text('Saltar', style: TextStyle(color: Color(0xFF64748B)))),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () { if (_step < _totalSteps) setState(() => _step++); else widget.onFinish(); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)), child: Text(_step == _totalSteps ? 'Entendido!' : 'Siguiente')),
            ]),
          ]),
        ),
      ),
    );
  }
}
