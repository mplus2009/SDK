import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/usuario.dart';

class QRService {
  static final GlobalKey _qrKey = GlobalKey();

  // Generar QR como widget
  static Widget generateQRWidget(Usuario usuario) {
    final qrData = base64Encode(utf8.encode(jsonEncode(usuario.toJson())));
    return RepaintBoundary(
      key: _qrKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200,
            gapless: false,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E3C72),
          ),
          const SizedBox(height: 10),
          Text(usuario.nombreCompleto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E3C72))),
        ]),
      ),
    );
  }

  // Mostrar modal QR
  static void showQRModal(BuildContext context, Usuario usuario) {
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
          generateQRWidget(usuario),
          const SizedBox(height: 15),
          Text('CI: ${usuario.ci}', style: const TextStyle(color: Color(0xFF64748B))),
          Text('Cargo: ${usuario.cargo}', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async => await _downloadQR(usuario, ctx),
              icon: const Icon(Icons.download),
              label: const Text('Descargar QR'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ]),
      ),
    );
  }

  // Descargar QR como imagen
  static Future<void> _downloadQR(Usuario usuario, BuildContext ctx) async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/QR_${usuario.nombreCompleto.replaceAll(' ', '_')}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('QR guardado en: ${file.path}'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
