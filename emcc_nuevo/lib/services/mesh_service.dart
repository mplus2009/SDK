import 'dart:async';

enum MeshStatus { disconnected, searching, connected, sending }

class MeshService {
  static final MeshService _instance = MeshService._();
  factory MeshService() => _instance;
  MeshService._();

  MeshStatus _status = MeshStatus.disconnected;
  String _deviceName = '';
  final StreamController<MeshStatus> _statusController = StreamController<MeshStatus>.broadcast();

  MeshStatus get status => _status;
  String get deviceName => _deviceName;
  Stream<MeshStatus> get statusStream => _statusController.stream;

  void startSearch() {
    _status = MeshStatus.searching;
    _statusController.add(_status);
    // Simula encontrar dispositivo
    Future.delayed(const Duration(seconds: 3), () {
      _deviceName = 'Prof. Martínez';
      _status = MeshStatus.connected;
      _statusController.add(_status);
    });
  }

  void sendData(String info) {
    _status = MeshStatus.sending;
    _statusController.add(_status);
    Future.delayed(const Duration(seconds: 1), () {
      _status = MeshStatus.connected;
      _statusController.add(_status);
    });
  }
}
