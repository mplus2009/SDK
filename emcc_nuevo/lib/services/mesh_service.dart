import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

enum MeshStatus { disconnected, searching, connected, sending }

class MeshService {
  static final MeshService _instance = MeshService._();
  factory MeshService() => _instance;
  MeshService._();

  MeshStatus _status = MeshStatus.disconnected;
  String _deviceName = '';
  List<String> _foundDevices = [];
  final _statusCtrl = StreamController<MeshStatus>.broadcast();

  MeshStatus get status => _status;
  String get deviceName => _deviceName;
  List<String> get foundDevices => _foundDevices;
  Stream<MeshStatus> get statusStream => _statusCtrl.stream;

  Future<void> startSearch() async {
    _status = MeshStatus.searching;
    _statusCtrl.add(_status);
    _foundDevices = [];
    
    // Buscar en la BD local usuarios como "dispositivos cercanos"
    try {
      final db = await DatabaseService.database;
      final estudiantes = await db.query('estudiante', limit: 5);
      final profesores = await db.query('profesor', limit: 3);
      final directiva = await db.query('directiva', limit: 2);
      
      for (final e in estudiantes) { _foundDevices.add('${e['nombre']} ${e['apellidos']} (Est.)'); }
      for (final p in profesores) { _foundDevices.add('${p['nombre']} ${p['apellidos']} (Prof.)'); }
      for (final d in directiva) { _foundDevices.add('${d['nombre']} ${d['apellidos']} (Dir.)'); }
      
      if (_foundDevices.isNotEmpty) {
        _deviceName = _foundDevices.first;
        _status = MeshStatus.connected;
      }
    } catch (_) {}
    
    _statusCtrl.add(_status);
  }

  Future<void> sendData(Map<String, dynamic> data) async {
    _status = MeshStatus.sending;
    _statusCtrl.add(_status);
    await Future.delayed(const Duration(seconds: 1));
    _status = MeshStatus.connected;
    _statusCtrl.add(_status);
  }

  void dispose() { _statusCtrl.close(); }
}
