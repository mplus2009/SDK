// ============================================
// PANTALLA DE ESCANER QR - CORREGIDO
// ============================================

import 'dart:convert';
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

  // ============================================
  // PROCESAR QR
  // ============================================
  void _procesarQR(String? code) {
    if (code == null || _procesando) return;
    setState(() => _procesando = true);

    try {
      Map<String, dynamic>? usuario = _decodificarQR(code);

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
      } else {
        _showSnackBar('QR no valido', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error al procesar QR', Colors.red);
    }

    // Esperar 2 segundos antes de permitir otro escaneo
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _procesando = false);
    });
  }

  // ============================================
  // DECODIFICAR QR (CORREGIDO)
  // ============================================
  Map<String, dynamic>? _decodificarQR(String code) {
    // Intento 1: JSON directo
    try {
      final data = jsonDecode(code);
      if (data is Map<String, dynamic>) {
        return {
          'id': '${data['id'] ?? ''}',
          'nombre': '${data['nombre'] ?? ''}',
          'apellidos': '${data['apellidos'] ?? ''}',
          'ci': '${data['ci'] ?? ''}',
          'grado': '${data['grado'] ?? '10mo'}',
          'cargo': '${data['cargo'] ?? 'estudiante'}',
        };
      }
    } catch (e) {
      // Continuar con otros intentos
    }

    // Intento 2: Base64 -> JSON
    try {
      final decoded = utf8.decode(base64Decode(code));
      final data = jsonDecode(decoded);
      if (data is Map<String, dynamic>) {
        return {
          'id': '${data['id'] ?? ''}',
          'nombre': '${data['nombre'] ?? ''}',
          'apellidos': '${data['apellidos'] ?? ''}',
          'ci': '${data['ci'] ?? ''}',
          'grado': '${data['grado'] ?? '10mo'}',
          'cargo': '${data['cargo'] ?? 'estudiante'}',
        };
      }
    } catch (e) {
      // Continuar con otros intentos
    }

    // Intento 3: Base64 (con reemplazo) -> JSON
    try {
      final fixed = code.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = utf8.decode(base64Decode(fixed));
      final data = jsonDecode(decoded);
      if (data is Map<String, dynamic>) {
        return {
          'id': '${data['id'] ?? ''}',
          'nombre': '${data['nombre'] ?? ''}',
          'apellidos': '${data['apellidos'] ?? ''}',
          'ci': '${data['ci'] ?? ''}',
          'grado': '${data['grado'] ?? '10mo'}',
          'cargo': '${data['cargo'] ?? 'estudiante'}',
        };
      }
    } catch (e) {
      // Continuar con otros intentos
    }

    // Intento 4: Formato simple separado por |
    try {
      final decoded = utf8.decode(base64Decode(code));
      final parts = decoded.split('|');
      if (parts.length >= 4) {
        return {
          'id': parts[0],
          'nombre': parts[1],
          'apellidos': parts[2],
          'ci': parts[3],
          'grado': parts.length > 4 ? parts[4] : '10mo',
          'cargo': parts.length > 5 ? parts[5] : 'estudiante',
        };
      }
    } catch (e) {
      // No se pudo decodificar
    }

    return null;
  }
  // ============================================
  // SNACKBAR
  // ============================================
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================
  // BUILD
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Escanear QR'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_escaneados.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _escaneados),
        ),
      ),
      body: Stack(
        children: [
          // Camara
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first;
                if (barcode.rawValue != null) {
                  _procesarQR(barcode.rawValue);
                }
              }
            },
          ),
          
          // Overlay con marco
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF10B981), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Esquina superior izquierda
                  Positioned(
                    top: -3,
                    left: -3,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
                      ),
                    ),
                  ),
                  // Esquina superior derecha
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
                      ),
                    ),
                  ),
                  // Esquina inferior izquierda
                  Positioned(
                    bottom: -3,
                    left: -3,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
                      ),
                    ),
                  ),
                  // Esquina inferior derecha
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Texto inferior
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Coloca el QR dentro del recuadro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
            ),
          ),
          
          // Loading
          if (_procesando)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          
          // Lista de escaneados
          if (_escaneados.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text(
                          'Estudiantes escaneados (${_escaneados.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3C72),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _escaneados.length,
                        itemBuilder: (context, index) {
                          final e = _escaneados[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF667EEA),
                                child: Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              title: Text(
                                '${e['nombre']} (${e['ci']})',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1E3C72)),
                              ),
                              subtitle: Text(
                                e['grado'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() => _escaneados.removeAt(index));
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, _escaneados),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Finalizar y Continuar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}