import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'database_service.dart';

enum MeshStatus { disconnected, scanning, connected, sending }

class MeshService {
  static final MeshService _instance = MeshService._();
  factory MeshService() => _instance;
  MeshService._();

  final _adapter = FlutterBluetoothSerial.instance;
  MeshStatus _status = MeshStatus.disconnected;
  List<BluetoothDevice> _devices = [];
  List<BluetoothConnection> _connections = [];
  final _statusCtrl = StreamController<MeshStatus>.broadcast();
  Timer? _scanTimer;

  MeshStatus get status => _status;
  List<BluetoothDevice> get devices => _devices;
  Stream<MeshStatus> get statusStream => _statusCtrl.stream;

  Future<void> start() async {
    final enabled = await _adapter.isEnabled;
    if (enabled == false) await _adapter.requestEnable();
    scan();
    _scanTimer = Timer.periodic(const Duration(seconds: 30), (_) => scan());
  }

  Future<void> scan() async {
    _status = MeshStatus.scanning;
    _statusCtrl.add(_status);
    try {
      _devices = await _adapter.getBondedDevices();
      if (_devices.isNotEmpty) {
        _status = MeshStatus.connected;
        _statusCtrl.add(_status);
        for (final d in _devices) {
          _connectAndSend(d);
        }
      }
    } catch (_) {}
  }

  Future<void> _connectAndSend(BluetoothDevice device) async {
    try {
      final conn = await BluetoothConnection.toAddress(device.address);
      _connections.add(conn);
      conn.input!.listen((data) async {
        final msg = String.fromCharCodes(data);
        try {
          final json = jsonDecode(msg);
          final db = await DatabaseService.database;
          await db.insert('actividad', Map<String, dynamic>.from(json));
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> sendToAll(Map<String, dynamic> data) async {
    _status = MeshStatus.sending;
    _statusCtrl.add(_status);
    final msg = jsonEncode(data);
    final bytes = Uint8List.fromList(utf8.encode(msg));
    for (final conn in _connections) {
      if (conn.isConnected) {
        try { conn.output.add(bytes); await conn.output.allSent; } catch (_) {}
      }
    }
    _status = MeshStatus.connected;
    _statusCtrl.add(_status);
  }

  void dispose() {
    _scanTimer?.cancel();
    for (final c in _connections) { c.dispose(); }
    _statusCtrl.close();
  }
}
