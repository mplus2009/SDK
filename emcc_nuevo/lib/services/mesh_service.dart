import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';

class MeshService {
  static bool _isRunning = false;
  static HttpServer? _server;
  static Timer? _discoveryTimer;
  static Timer? _syncTimer;
  static final List<String> _peers = [];
  static const int _port = 8888;
  static String _mode = 'none';
  static StreamSubscription<ConnectivityResult>? _connectivitySub;

  static Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    _startServer();
    _monitorConnectivity();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 15), (_) => _discoverPeers());
    _syncTimer = Timer.periodic(const Duration(seconds: 20), (_) => _syncWithPeers());
  }

  static void stop() {
    _isRunning = false;
    _server?.close();
    _discoveryTimer?.cancel();
    _syncTimer?.cancel();
    _connectivitySub?.cancel();
    _peers.clear();
  }

  static void _monitorConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.wifi) {
        _mode = 'wifi';
        debugPrint('📶 Modo WiFi Direct activado');
        _discoverPeers();
      } else if (result == ConnectivityResult.bluetooth) {
        _mode = 'bluetooth';
        debugPrint('🔵 Modo Bluetooth activado');
        _peers.add('bluetooth-mesh');
      }
    });
  }

  static Future<void> _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      debugPrint('🟢 Servidor Mesh en puerto $_port');
      _server!.listen((request) async {
        try {
          if (request.method == 'POST' && request.uri.path == '/sync') {
            final body = await utf8.decodeStream(request);
            final data = jsonDecode(body);
            await _receiveData(data);
            request.response.statusCode = 200;
            request.response.write('{"status":"ok"}');
          } else if (request.uri.path == '/ping') {
            request.response.statusCode = 200;
            request.response.write('{"device":"EMCC","mode":"$_mode"}');
          }
          await request.response.close();
        } catch (e) {
          debugPrint('Error en servidor: $e');
        }
      });
    } catch (e) {
      debugPrint('🔴 Error servidor: $e');
    }
  }

  static Future<void> _discoverPeers() async {
    if (_mode != 'wifi') return;
    try {
      final interfaces = await NetworkInterface.list();
      if (interfaces.isEmpty) return;
      final localIP = interfaces.first.addresses.first.address;
      final subnet = localIP.substring(0, localIP.lastIndexOf('.'));
      for (int i = 1; i <= 254; i++) {
        final host = '$subnet.$i';
        if (host == localIP) continue;
        try {
          final client = HttpClient();
          client.connectionTimeout = const Duration(milliseconds: 300);
          final request = await client.getUrl(Uri.parse('http://$host:$_port/ping'));
          final response = await request.close();
          if (response.statusCode == 200 && !_peers.contains(host)) {
            _peers.add(host);
            debugPrint('🔵 Peer WiFi encontrado: $host');
          }
        } catch (e) {}
      }
    } catch (e) {
      debugPrint('Error WiFi Direct: $e');
    }
  }

  static Future<void> _syncWithPeers() async {
    if (_peers.isEmpty) return;
    for (final peer in _peers.toList()) {
      try {
        if (peer == 'bluetooth-mesh') continue;
        final db = await DatabaseService.database;
        final localActs = await db.query('actividad', orderBy: 'id DESC', limit: 30);
        if (localActs.isEmpty) continue;
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse('http://$peer:$_port/sync'));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'actividades': localActs}));
        await request.close();
        debugPrint('✅ Sincronizado con $peer');
      } catch (e) {
        _peers.remove(peer);
      }
    }
  }

  static Future<void> _receiveData(Map<String, dynamic> data) async {
    try {
      final db = await DatabaseService.database;
      final acts = (data['actividades'] as List<dynamic>?) ?? [];
      for (final act in acts) {
        final exists = await db.query('actividad', where: 'id = ?', whereArgs: [act['id']]);
        if (exists.isEmpty) {
          await db.insert('actividad', Map<String, dynamic>.from(act));
          debugPrint('📥 Recibido: ${act['falta_causa']}');
        }
      }
    } catch (e) {
      debugPrint('Error recibiendo: $e');
    }
  }

  static Future<void> broadcast(Map<String, dynamic> act) async {
    for (final peer in _peers) {
      try {
        if (peer == 'bluetooth-mesh') continue;
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse('http://$peer:$_port/sync'));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'actividades': [act]}));
        await request.close();
      } catch (e) {}
    }
  }
}
