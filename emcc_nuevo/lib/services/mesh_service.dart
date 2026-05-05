import 'dart:async';
import 'package:flutter/services.dart';

enum MeshStatus { disconnected, searching, connected, sending, serverOn }

class MeshService {
  static final MeshService _instance = MeshService._();
  factory MeshService() => _instance;
  MeshService._();

  static const _channel = MethodChannel('com.emcc.mesh/channel');
  
  MeshStatus _status = MeshStatus.disconnected;
  List<String> _devices = [];
  final _statusCtrl = StreamController<MeshStatus>.broadcast();

  MeshStatus get status => _status;
  List<String> get devices => _devices;
  Stream<MeshStatus> get statusStream => _statusCtrl.stream;

  Future<void> startServer() async {
    try {
      await _channel.invokeMethod('startServer', {'port': 8080});
      _status = MeshStatus.serverOn;
      _statusCtrl.add(_status);
    } catch (e) {
      _status = MeshStatus.disconnected;
      _statusCtrl.add(_status);
    }
  }

  Future<void> searchDevices() async {
    _status = MeshStatus.searching;
    _statusCtrl.add(_status);
    try {
      final devices = await _channel.invokeMethod('discoverPeers');
      _devices = List<String>.from(devices ?? []);
      _status = _devices.isNotEmpty ? MeshStatus.connected : MeshStatus.disconnected;
    } catch (e) {
      _status = MeshStatus.disconnected;
    }
    _statusCtrl.add(_status);
  }

  Future<void> sendToAll(Map<String, dynamic> data) async {
    _status = MeshStatus.sending;
    _statusCtrl.add(_status);
    try {
      await _channel.invokeMethod('sendToAll', {'data': data});
    } catch (_) {}
    _status = MeshStatus.connected;
    _statusCtrl.add(_status);
  }

  void dispose() { _statusCtrl.close(); }
}
