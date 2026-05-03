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
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'emcc_sistema.db');
    if (!await File(dbPath).exists()) {
      final data = await rootBundle.load('assets/db/emcc_sistema.db');
      await File(dbPath).writeAsBytes(data.buffer.asUint8List());
    }
    return await openDatabase(dbPath, version: 1);
  }

  static Future<bool> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('usuario');
    if (json != null) { _usuario = Usuario.fromJson(jsonDecode(json)); return true; }
    return false;
  }

  static Future<void> saveSession(Usuario u) async {
    _usuario = u;
    (await SharedPreferences.getInstance()).setString('usuario', jsonEncode(u.toJson()));
  }

  static Future<void> logout() async {
    _usuario = null;
    (await SharedPreferences.getInstance()).clear();
  }

  static Future<Map<String, dynamic>> login(String nombre, String apellidos, String password, String cargo) async {
    final db = await database;
    String t = cargo;
    final r = await db.query(t, where: 'nombre=? AND apellidos=? AND password=?', whereArgs: [nombre, apellidos, password], limit: 1);
    if (r.isNotEmpty) {
      final u = r.first;
      final user = Usuario(id: u['id'], nombre: u['nombre'], apellidos: u['apellidos'], ci: u['CI'] ?? '', cargo: cargo, ocupacion: u['ocupacion'], grado: u['grado'], peloton: u['peloton']);
      await saveSession(user);
      return {'success': true, 'usuario': user.toJson()};
    }
    return {'success': false};
  }

  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String q) async {
    final db = await database;
    return db.rawQuery("SELECT * FROM estudiante WHERE nombre LIKE ? OR apellidos LIKE ? OR CI LIKE ? LIMIT 30", ['%$q%', '%$q%', '%$q%']);
  }

  static Future<List<Map<String, dynamic>>> getCatalogo(String tipo) async {
    return (await database).query(tipo == 'merito' ? 'meritos' : 'demeritos');
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    if (_usuario == null) return {'success': false};
    final db = await database;
    final id = '${_usuario!.cargo}_${_usuario!.id}';
    final m = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) t FROM actividad WHERE id_end=? AND tipo="merito"', [id]);
    final d = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) t FROM actividad WHERE id_end=? AND tipo="demerito"', [id]);
    return {'success': true, 'stats': {'meritos': m.first['t'], 'demeritos': d.first['t'], 'balance': (m.first['t']??0) - (d.first['t']??0)}};
  }

  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> data) async {
    final db = await database;
    for (final dest in data['destinatarios'])
      for (final act in data['actividades'])
        await db.insert('actividad', {'id_star': '${data['cargo_notificador']}_${data['id_star']}', 'id_end': 'estudiante_${dest['id']}', 'tipo': act['tipo'], 'categoria': act['categoria'], 'falta_causa': act['nombre'], 'cantidad': act['cantidad'], 'fecha': data['fecha'], 'hora': data['hora'], 'observaciones': data['observaciones']??'', 'leido': 0});
    return {'success': true};
  }

  static Future<Map<String, dynamic>> verificarNotificador(String nombre, String password) async {
    final db = await database;
    final p = nombre.trim().split(' ');
    for (final t in ['estudiante','profesor','oficial','directiva']) {
      final r = await db.query(t, where: 'nombre=? AND apellidos=? AND password=?', whereArgs: [p[0], p.length>1?p.sublist(1).join(' '):'', password], limit: 1);
      if (r.isNotEmpty) return {'success': true, 'id': r.first['id'], 'nombre': '${r.first['nombre']} ${r.first['apellidos']}', 'cargo': t};
    }
    return {'success': false};
  }
}
