import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'mesh_service.dart';

class DatabaseService {
  static Database? _db;
  static Usuario? _u;
  static Usuario? get usuario => _u;
  static bool get isLoggedIn => _u != null;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final p = join(await getDatabasesPath(), 'emcc.db');
    if (!File(p).existsSync()) {
      final d = await rootBundle.load('assets/data/emcc_sistema.db');
      await File(p).writeAsBytes(d.buffer.asUint8List());
    }
    return await openDatabase(p);
  }

  static Future<bool> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final j = prefs.getString('usuario');
    if (j != null) { _u = Usuario.fromJson(jsonDecode(j)); return true; }
    return false;
  }

  static Future<void> saveSession(Usuario u) async {
    _u = u;
    (await SharedPreferences.getInstance()).setString('usuario', jsonEncode(u.toJson()));
  }

  static Future<void> logout() async {
    _u = null;
    (await SharedPreferences.getInstance()).clear();
  }

  static Future<Map<String, dynamic>> login(String n, String a, String p, String c) async {
    final db = await database;
    final r = await db.query(c, where: 'nombre=? AND apellidos=? AND password=?', whereArgs: [n, a, p], limit: 1);
    if (r.isNotEmpty) {
      final x = r.first;
      final u = Usuario(id: int.tryParse('${x['id']}')??0, nombre: '${x['nombre']}', apellidos: '${x['apellidos']}', ci: '${x['CI']??''}', cargo: c, ocupacion: x['ocupacion']?.toString(), grado: x['grado']?.toString(), peloton: int.tryParse('${x['peloton']}'));
      await saveSession(u);
      return {'success': true};
    }
    return {'success': false};
  }

  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String q) async {
    final db = await database;
    return await db.query('estudiante', where: 'nombre LIKE ? OR apellidos LIKE ? OR CI LIKE ?', whereArgs: ['%$q%','%$q%','%$q%'], limit: 30);
  }

  static Future<List<Map<String, dynamic>>> getCatalogo(String t) async {
    final db = await database;
    return await db.query(t == 'merito' ? 'meritos' : 'demeritos');
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    return {'success': true, 'stats': {'meritos_semana': 0, 'demeritos_semana': 0, 'balance_semana': 0}, 'semana_actual': [], 'semana_fecha': '', 'alarma_activa': false};
  }

  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> d) async {
    final db = await database;
    int insertados = 0;
    for (final dest in d['destinatarios']) {
      for (final act in d['actividades']) {
        await db.insert('actividad', {'id_star': '${d['cargo_notificador']}_${d['id_star']}', 'id_end': 'estudiante_${dest['id']}', 'tipo': act['tipo'], 'categoria': act['categoria'], 'falta_causa': act['nombre'], 'cantidad': act['cantidad'], 'fecha': d['fecha'], 'hora': d['hora'], 'leido': 0});
        insertados++;
      }
    }
    try { await MeshService().sendToAll(d); } catch (_) {}
    return {'success': true};
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    return {'success': true, 'stats': {'meritos': 0, 'demeritos': 0}, 'ultimas_actividades': []};
  }

  static Future<Map<String, dynamic>> verificarNotificador(String n, String p) async {
    return {'success': false};
  }
}
