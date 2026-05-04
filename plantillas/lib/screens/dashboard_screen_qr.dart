import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class QRModal {
  static void mostrar(BuildContext context, String qrData, String nombre) {
    // Datos para el QR
    final Map<String, dynamic> datos = {
      'id': DatabaseService.usuario?.id ?? 0,
      'nombre': DatabaseService.usuario?.nombre ?? '',
      'apellidos': DatabaseService.usuario?.apellidos ?? '',
      'ci': DatabaseService.usuario?.ci ?? '',
      'cargo': DatabaseService.usuario?.cargo ?? '',
    };
    final qrString = Uri.encodeComponent(convertEncode(datos));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Tu Código QR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72))),
          const SizedBox(height: 20),
          RepaintBoundary(
            key: qrKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25)]),
              child: Column(children: [
                QrImageView(data: qrString, version: QrVersions.auto, size: 200.0, backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E3C72)),
                const SizedBox(height: 10),
                Text(nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E3C72))),
              ]),
            ),
          ),
          const SizedBox(height: 15),
          Text('CI: ${DatabaseService.usuario?.ci ?? ""}', style: const TextStyle(color: Color(0xFF64748B))),
          Text('Cargo: ${DatabaseService.usuario?.cargo ?? ""}', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final RenderRepaintBoundary? boundary = qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                  if (boundary == null) return;
                  final image = await boundary.toImage(pixelRatio: 3.0);
                  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                  if (byteData == null) return;
                  final dir = await getApplicationDocumentsDirectory();
                  final file = File('${dir.path}/qr_${nombre.replaceAll(" ", "_")}.png');
                  await file.writeAsBytes(byteData.buffer.asUint8List());
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('QR guardado en: ${file.path}'), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Descargar QR'),
            ),
          ),
        ]),
      ),
    );
  }

  static String convertEncode(Map<String, dynamic> data) {
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  static String base64Encode(String data) {
    return 'base64placeholder';
  }

  static String jsonEncode(Map<String, dynamic> data) {
    return '{"id":${data['id']},"nombre":"${data['nombre']}","apellidos":"${data['apellidos']}","ci":"${data['ci']}","cargo":"${data['cargo']}"}';
  }

  static String utf8Decode(String data) {
    return data;
  }

  static final GlobalKey qrKey = GlobalKey();
}
