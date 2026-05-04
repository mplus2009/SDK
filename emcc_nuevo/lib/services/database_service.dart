import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

class DatabaseService {
  static Database? _database;
  static Usuario? _usuario;

  static Usuario? get usuario => _usuario;
  static bool get isLoggedIn => _usuario != null;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'emcc_sistema.db');
    if (!File(path).existsSync()) {
      final data = await rootBundle.load('assets/data/emcc_sistema.db');
      final bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes);
    }
    return await openDatabase(path, version: 2);
  }

  static Future<bool> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString('usuario');
    if (usuarioJson != null) {
      _usuario = Usuario.fromJson(jsonDecode(usuarioJson));
      return true;
    }
    return false;
  }

  static Future<void> saveSession(Usuario usuario) async {
    _usuario = usuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(usuario.toJson()));
  }

  static Future<void> logout() async {
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>> login(String nombre, String apellidos, String password, String cargo) async {
    try {
      final db = await database;
      final r = await db.query(cargo, where: 'nombre=? AND apellidos=? AND password=?', whereArgs: [nombre, apellidos, password], limit: 1);
      if (r.isNotEmpty) {
        final u = r.first;
        final usuario = Usuario(
          id: int.tryParse(u['id'].toString()) ?? 0,
          nombre: u['nombre'].toString(),
          apellidos: u['apellidos'].toString(),
          ci: (u['CI'] ?? '').toString(),
          cargo: cargo,
          ocupacion: u['ocupacion']?.toString(),
          grado: u['grado']?.toString(),
          peloton: int.tryParse(u['peloton']?.toString() ?? ''),
        );
        await saveSession(usuario);
        return {'success': true};
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }

  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String query) async {
    final db = await database;
    return await db.query('estudiante', where: 'nombre LIKE ? OR apellidos LIKE ? OR CI LIKE ?', whereArgs: ['%$query%', '%$query%', '%$query%'], limit: 30);
  }

  static Future<List<Map<String, dynamic>>> getCatalogo(String tipo) async {
    final db = await database;
    return await db.query(tipo == 'merito' ? 'meritos' : 'demeritos', orderBy: 'id');
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    if (_usuario == null) return {'success': false};
    final db = await database;
    final act = await db.query('actividad', where: 'id_end=?', whereArgs: ['${_usuario!.cargo}_${_usuario!.id}'], orderBy: 'fecha DESC', limit: 20);
    return {'success': true, 'stats': {'meritos_semana': 0, 'demeritos_semana': 0, 'balance_semana': 0}, 'semana_actual': act, 'semana_fecha': '', 'alarma_activa': false};
  }

  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> data) async {
    final db = await database;
    for (final dest in (data['destinatarios'] as List)) {
      for (final act in (data['actividades'] as List)) {
        await db.insert('actividad', {'id_star': '${data['cargo_notificador']}_${data['id_star']}', 'id_end': 'estudiante_${dest['id']}', 'tipo': act['tipo'], 'categoria': act['categoria'], 'falta_causa': act['nombre'], 'cantidad': act['cantidad'], 'fecha': data['fecha'], 'hora': data['hora'], 'observaciones': data['observaciones'] ?? '', 'leido': 0});
      }
    }
    return {'success': true};
  }

  static Future<Map<String, dynamic>> getPerfil() async { return {'success': true, 'stats': {'meritos': 0, 'demeritos': 0}, 'ultimas_actividades': []}; }
  static Future<Map<String, dynamic>> verificarNotificador(String nombre, String password) async { return {'success': false}; }
}
