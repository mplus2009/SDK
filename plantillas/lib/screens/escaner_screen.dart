// ============================================
// PANTALLA DE ESCANER QR
// ============================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EscanerScreen extends StatefulWidget {
  const EscanerScreen({super.key});

  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  List<Map<String, dynamic>> _escaneados = [];
  bool _procesando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _procesarQR(String? code) {
    if (code == null || _procesando) return;
    setState(() => _procesando = true);

    try {
      Map<String, dynamic>? usuario;

      // Intentar decodificar
      try { usuario = _decodificarBase64(code); } catch (e) {}
      if (usuario == null) {
        try { usuario = _decodificarBase64(code.replaceAll('-', '+').replaceAll('_', '/')); } catch (e) {}
      }
      if (usuario == null) {
        try { usuario = Map<String, dynamic>.from(Uri.parse(code).queryParameters); } catch (e) {}
      }

      if (usuario != null && usuario['nombre'] != null && usuario['apellidos'] != null) {
        final id = '${usuario['id'] ?? ''}';
        final existe = _escaneados.any((e) => e['id'] == id);

        if (!existe) {
          setState(() {
            _escaneados.add({
              'id': id,
              'nombre': '${usuario!['nombre']} ${usuario['apellidos']}',
              'ci': '${usuario['ci'] ?? ''}',
              'grado': '${usuario['grado'] ?? '10mo'}',
            });
          });
          _showSnackBar('Estudiante escaneado!', Colors.green);
        } else {
          _showSnackBar('Ya esta en la lista', Colors.orange);
        }
      }
    } catch (e) {
      _showSnackBar('QR no valido', Colors.red);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _procesando = false);
    });
  }

  Map<String, dynamic>? _decodificarBase64(String code) {
    try {
      final decoded = String.fromCharCodes(base64Decode(code));
      final parts = decoded.split('|');
      if (parts.length >= 4) {
        return {
          'id': parts[0],
          'nombre': parts[1],
          'apellidos': parts[2],
          'ci': parts[3],
          'grado': parts.length > 4 ? parts[4] : '10mo',
        };
      }
    } catch (e) {}
    return null;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('Escanear QR'),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(20)), child: Text('${_escaneados.length}', style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, _escaneados)),
      ),
      body: Stack(
        children: [
          // Camara
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                _procesarQR(barcode.rawValue);
              }
            },
          ),
          // Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF10B981), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(children: [
                Positioned(top: -3, left: -3, child: Container(width: 25, height: 25, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 4), left: BorderSide(color: Colors.white, width: 4)), borderRadius: BorderRadius.only(topLeft: Radius.circular(8))))),
                Positioned(top: -3, right: -3, child: Container(width: 25, height: 25, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white, width: 4), right: BorderSide(color: Colors.white, width: 4)), borderRadius: BorderRadius.only(topRight: Radius.circular(8))))),
                Positioned(bottom: -3, left: -3, child: Container(width: 25, height: 25, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 4), left: BorderSide(color: Colors.white, width: 4)), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8))))),
                Positioned(bottom: -3, right: -3, child: Container(width: 25, height: 25, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 4), right: BorderSide(color: Colors.white, width: 4)), borderRadius: BorderRadius.only(bottomRight: Radius.circular(8))))),
              ]),
            ),
          ),
          // Texto
          const Positioned(bottom: 100, left: 0, right: 0, child: Center(child: Text('Coloca el QR dentro del recuadro', style: TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(color: Colors.black, blurRadius: 10)])))),
          // Loading
          if (_procesando) const Center(child: CircularProgressIndicator(color: Colors.white)),
          // Lista de escaneados
          if (_escaneados.isNotEmpty)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Estudiantes escaneados (${_escaneados.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3C72))),
                  const SizedBox(height: 10),
                  SizedBox(height: 100, child: ListView.builder(
                    itemCount: _escaneados.length,
                    itemBuilder: (context, index) {
                      final e = _escaneados[index];
                      return ListTile(dense: true, title: Text('${e['nombre']} (${e['ci']})'), subtitle: Text(e['grado'] ?? ''), trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() => _escaneados.removeAt(index))));
                    },
                  )),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.pop(context, _escaneados), icon: const Icon(Icons.check_circle), label: const Text('Finalizar y Continuar'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)))),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}