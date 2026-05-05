import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

enum MeshStatus { disconnected, searching, connected, sending, serverOn }

class MeshService {
  static final MeshService _instance = MeshService._();
  factory MeshService() => _instance;
  MeshService._();

  static const _channel = MethodChannel('com.emcc.mesh/channel');
  
  MeshStatus _status = MeshStatus.disconnected;
  List<String> _devices = [];
  String _myIp = '';
  int _port = 8080;
  final _statusCtrl = StreamController<MeshStatus>.broadcast();
  Timer? _searchTimer;

  MeshStatus get status => _status;
  List<String> get devices => _devices;
  String get myIp => _myIp;
  Stream<MeshStatus> get statusStream => _statusCtrl.stream;

  Future<void> startServer() async {
    try {
      // Intentar iniciar plugin nativo
      await _channel.invokeMethod('startServer', {'port': _port});
    } catch (_) {
      // Si falla, iniciar servidor HTTP normal
      try {
        await HttpServer.bind(InternetAddress.anyIPv4, _port);
      } catch (_) {}
    }
    
    // Obtener IP local
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            _myIp = addr.address;
          }
        }
      }
    } catch (_) {}

    if (_myIp.isNotEmpty && _myIp != '127.0.0.1') {
      _status = MeshStatus.serverOn;
      _statusCtrl.add(_status);
      // Auto-buscar cada 30 segundos
      _searchTimer?.cancel();
      _searchTimer = Timer.periodic(const Duration(seconds: 30), (_) => searchDevices());
      // Primera búsqueda
      searchDevices();
    }
  }

  Future<void> searchDevices() async {
    _status = MeshStatus.searching;
    _statusCtrl.add(_status);
    _devices = [];
    
    if (_myIp.isEmpty || _myIp == '127.0.0.1') {
      _status = MeshStatus.disconnected;
      _statusCtrl.add(_status);
      return;
    }
    
    final subnet = _myIp.substring(0, _myIp.lastIndexOf('.'));
    
    // Escanear rango limitado
    for (var i = 100; i <= 115; i++) {
      final ip = '$subnet.$i';
      if (ip == _myIp) continue;
      try {
        final res = await http.get(Uri.parse('http://$ip:$_port/ping')).timeout(const Duration(milliseconds: 200));
        if (res.statusCode == 200) {
          _devices.add(ip);
        }
      } catch (_) {}
    }
    
    // También intentar vía plugin nativo
    try {
      final nativeDevices = await _channel.invokeMethod('discoverPeers');
      if (nativeDevices != null) {
        for (final d in List<String>.from(nativeDevices)) {
          if (!_devices.contains(d)) _devices.add(d);
        }
      }
    } catch (_) {}
    
    _status = _devices.isNotEmpty ? MeshStatus.connected : MeshStatus.disconnected;
    _statusCtrl.add(_status);
  }

  Future<void> sendToAll(Map<String, dynamic> data) async {
    if (_devices.isEmpty) return;
    _status = MeshStatus.sending;
    _statusCtrl.add(_status);
    
    for (final ip in _devices) {
      try {
        await http.post(Uri.parse('http://$ip:$_port/sync'), body: data.toString()).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    
    _status = MeshStatus.connected;
    _statusCtrl.add(_status);
  }

  void dispose() { _searchTimer?.cancel(); _statusCtrl.close(); }
}
