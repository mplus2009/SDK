import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';

enum MeshStatus { disconnected, searching, connected, sending, serverOn }

class MeshService {
  static final MeshService _instance = MeshService._();
  factory MeshService() => _instance;
  MeshService._();

  MeshStatus _status = MeshStatus.disconnected;
  String _myIp = '';
  int _port = 8080;
  List<Map<String, String>> _foundDevices = [];
  HttpServer? _server;
  final _statusCtrl = StreamController<MeshStatus>.broadcast();
  static const _channel = MethodChannel('emcc_mesh');

  MeshStatus get status => _status;
  String get myIp => _myIp;
  int get port => _port;
  List<Map<String, String>> get foundDevices => _foundDevices;
  Stream<MeshStatus> get statusStream => _statusCtrl.stream;

  Future<void> startServer() async {
    try {
      final router = Router();
      router.get('/ping', (req) => shelf.Response.ok('EMCC_OK'));
      router.post('/sync', _handleSync);
      _server = await shelf_io.serve(router, InternetAddress.anyIPv4, _port);
      _myIp = await _getLocalIp();
      _status = MeshStatus.serverOn;
      _statusCtrl.add(_status);
      // Emitir por WiFi "estoy aquí"
      _broadcastPresence();
    } catch (e) {
      _status = MeshStatus.disconnected;
      _statusCtrl.add(_status);
    }
  }

  Future<shelf.Response> _handleSync(shelf.Request req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body);
    try {
      final db = await DatabaseService.database;
      await db.insert('actividad', Map<String, dynamic>.from(data));
      return shelf.Response.ok('OK');
    } catch (e) {
      return shelf.Response.internalServerError(body: '$e');
    }
  }

  Future<String> _getLocalIp() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) return addr.address;
      }
    }
    return '127.0.0.1';
  }

  void _broadcastPresence() {
    // Enviar broadcast UDP para que otros dispositivos nos encuentren
    // sin necesidad de escanear todas las IPs
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final RawDatagramSocket socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888);
        socket.broadcastEnabled = true;
        final msg = utf8.encode('EMCC:$_myIp:$_port');
        socket.send(msg, InternetAddress('255.255.255.255'), 8888);
        socket.close();
      } catch (_) {}
    });
  }

  Future<void> searchDevices() async {
    _status = MeshStatus.searching;
    _statusCtrl.add(_status);
    _foundDevices = [];

    // Escuchar broadcasts UDP de otros dispositivos
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 8888);
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final msg = utf8.decode(datagram.data);
            if (msg.startsWith('EMCC:')) {
              final parts = msg.split(':');
              if (parts.length >= 3) {
                final ip = parts[1];
                final port = parts[2];
                if (ip != _myIp) {
                  final exists = _foundDevices.any((d) => d['ip'] == ip);
                  if (!exists) {
                    _foundDevices.add({'ip': ip, 'name': 'EMCC ($ip)'});
                    _status = MeshStatus.connected;
                    _statusCtrl.add(_status);
                  }
                }
              }
            }
          }
        }
      });
      // Esperar 5 segundos para recibir broadcasts
      await Future.delayed(const Duration(seconds: 5));
      socket.close();
    } catch (_) {}

    if (_foundDevices.isEmpty) {
      // Fallback: escanear IPs locales
      if (_myIp.isNotEmpty && _myIp != '127.0.0.1') {
        final subnet = _myIp.substring(0, _myIp.lastIndexOf('.'));
        for (var i = 100; i <= 120; i++) {
          final ip = '$subnet.$i';
          if (ip == _myIp) continue;
          try {
            final res = await http.get(Uri.parse('http://$ip:$_port/ping')).timeout(const Duration(milliseconds: 300));
            if (res.body == 'EMCC_OK') _foundDevices.add({'ip': ip, 'name': 'WiFi ($ip)'});
          } catch (_) {}
        }
      }
      _status = _foundDevices.isNotEmpty ? MeshStatus.connected : MeshStatus.disconnected;
    }
    _statusCtrl.add(_status);
  }

  Future<void> sendToAll(Map<String, dynamic> data) async {
    if (_foundDevices.isEmpty) return;
    _status = MeshStatus.sending;
    _statusCtrl.add(_status);
    final msg = jsonEncode(data);
    for (final device in _foundDevices) {
      try {
        await http.post(Uri.parse('http://${device['ip']}:$_port/sync'), body: msg).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    _status = MeshStatus.connected;
    _statusCtrl.add(_status);
  }

  void dispose() { _statusCtrl.close(); _server?.close(force: true); }
}
