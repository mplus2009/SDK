import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

enum MeshStatus { disconnected, searching, connected, sending, serverOn }

class MeshService {
  static final MeshService _instance = MeshService._();
  factory MeshService() => _instance;
  MeshService._();

  MeshStatus _status = MeshStatus.disconnected;
  String _deviceName = '';
  String _myIp = '';
  int _port = 8080;
  List<String> _foundDevices = [];
  HttpServer? _server;
  final _statusCtrl = StreamController<MeshStatus>.broadcast();

  MeshStatus get status => _status;
  String get deviceName => _deviceName;
  String get myIp => _myIp;
  int get port => _port;
  List<String> get foundDevices => _foundDevices;
  Stream<MeshStatus> get statusStream => _statusCtrl.stream;

  Future<void> startServer() async {
    final router = Router();
    
    router.get('/ping', (req) => shelf.Response.ok('EMCC_OK'));
    
    router.post('/sync', (req) async {
      final body = await req.readAsString();
      final data = jsonDecode(body);
      try {
        final db = await DatabaseService.database;
        await db.insert('actividad', Map<String, dynamic>.from(data));
        _status = MeshStatus.sending;
        _statusCtrl.add(_status);
        await Future.delayed(const Duration(milliseconds: 500));
        _status = MeshStatus.connected;
        _statusCtrl.add(_status);
        return shelf.Response.ok('OK');
      } catch (e) {
        return shelf.Response.internalServerError(body: '$e');
      }
    });

    _server = await shelf_io.serve(router, InternetAddress.anyIPv4, _port);
    _myIp = await _getLocalIp();
    _status = MeshStatus.serverOn;
    _statusCtrl.add(_status);
    print('🌐 Servidor iniciado en $_myIp:$_port');
  }

  Future<String> _getLocalIp() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return '127.0.0.1';
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _status = MeshStatus.disconnected;
    _statusCtrl.add(_status);
  }

  Future<void> searchDevices() async {
    _status = MeshStatus.searching;
    _statusCtrl.add(_status);
    _foundDevices = [];
    
    // Escanear red local en busca de otros servidores EMCC
    final subnet = _myIp.substring(0, _myIp.lastIndexOf('.'));
    for (var i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      if (ip == _myIp) continue;
      try {
        final response = await http.get(Uri.parse('http://$ip:$_port/ping')).timeout(const Duration(milliseconds: 500));
        if (response.body == 'EMCC_OK') {
          _foundDevices.add(ip);
        }
      } catch (_) {}
    }
    
    if (_foundDevices.isNotEmpty) {
      _deviceName = _foundDevices.first;
      _status = MeshStatus.connected;
    } else {
      _status = MeshStatus.disconnected;
    }
    _statusCtrl.add(_status);
  }

  Future<void> sendToAll(Map<String, dynamic> data) async {
    _status = MeshStatus.sending;
    _statusCtrl.add(_status);
    for (final ip in _foundDevices) {
      try {
        await http.post(Uri.parse('http://$ip:$_port/sync'), body: jsonEncode(data)).timeout(const Duration(seconds: 3));
      } catch (e) {
        print('Error enviando a $ip: $e');
      }
    }
    _status = MeshStatus.connected;
    _statusCtrl.add(_status);
  }

  void dispose() { _statusCtrl.close(); stopServer(); }
}
