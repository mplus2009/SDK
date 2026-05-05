import 'mesh_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

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
      final data = await rootBundle.load('assets/data/emcc_sistema.db');
      await File(p).writeAsBytes(data.buffer.asUint8List());
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

  static Future<void> logout() async { _u = null; (await SharedPreferences.getInstance()).clear(); }

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
    return await db.rawQuery("SELECT e.*, COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end='estudiante_'||e.id AND tipo='merito'),0) as meritos, COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end='estudiante_'||e.id AND tipo='demerito'),0) as demeritos FROM estudiante e WHERE e.nombre LIKE ? OR e.apellidos LIKE ? OR e.CI LIKE ? LIMIT 30", ['%$q%','%$q%','%$q%']);
  }

  static Future<List<Map<String, dynamic>>> getCatalogo(String t) async {
    final db = await database;
    final tabla = t == 'merito' ? 'meritos' : 'demeritos';
    final results = await db.query(tabla, orderBy: 'id');
    // Corregir: asegurar que meritos, demeritos_10mo, demeritos_11_12 sean números
    return results.map((row) {
      final newRow = Map<String, dynamic>.from(row);
      if (t == 'merito') {
        newRow['meritos'] = int.tryParse('${row['meritos']??'0'}') ?? 0;
      } else {
        newRow['demeritos_10mo'] = '${row['demeritos_10mo']??'1'}';
        newRow['demeritos_11_12'] = '${row['demeritos_11_12']??'1'}';
      }
      return newRow;
    }).toList();
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    if (_u == null) return {'success': false};
    final db = await database;
    final idF = '${_u!.cargo}_${_u!.id}';
    final hoy = DateTime.now();
    final dias = hoy.weekday >= 3 ? hoy.weekday - 3 : hoy.weekday + 4;
    final inicio = hoy.subtract(Duration(days: dias)).toString().split(' ')[0];
    // Contadores
    final m = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) as t FROM actividad WHERE id_end=? AND tipo=? AND fecha>=?', [idF, 'merito', inicio]);
    final d = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) as t FROM actividad WHERE id_end=? AND tipo=? AND fecha>=?', [idF, 'demerito', inicio]);
    // Actividades con nombre del notificador
    final act = await db.rawQuery("SELECT a.*, CASE WHEN a.id_star LIKE 'estudiante_%' THEN (SELECT nombre||' '||apellidos FROM estudiante WHERE id=SUBSTR(a.id_star, INSTR(a.id_star,'_')+1)) WHEN a.id_star LIKE 'profesor_%' THEN (SELECT nombre||' '||apellidos FROM profesor WHERE id=SUBSTR(a.id_star, INSTR(a.id_star,'_')+1)) WHEN a.id_star LIKE 'directiva_%' THEN (SELECT nombre||' '||apellidos FROM directiva WHERE id=SUBSTR(a.id_star, INSTR(a.id_star,'_')+1)) ELSE 'Sistema' END as notificador FROM actividad a WHERE a.id_end=? AND a.fecha>=? ORDER BY a.fecha DESC, a.hora DESC", [idF, inicio]);
    final n = await db.rawQuery('SELECT COUNT(*) as c FROM actividad WHERE id_end=? AND leido=0', [idF]);
    final mVal = (m.first['t'] as int?) ?? 0;
    final dVal = (d.first['t'] as int?) ?? 0;
    return {'success': true, 'stats': {'meritos_semana': mVal, 'demeritos_semana': dVal, 'balance_semana': mVal - dVal}, 'semana_actual': act, 'semana_fecha': inicio, 'nuevas_actividades': (n.first['c'] as int?) ?? 0, 'alarma_activa': dVal >= 15};
  }

  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> d) async {
    final db = await database;
    for (final dest in d['destinatarios']) {
      for (final act in d['actividades']) {
        await db.insert('actividad', {'id_star': '${d['cargo_notificador']}_${d['id_star']}', 'id_end': 'estudiante_${dest['id']}', 'tipo': act['tipo'], 'categoria': act['categoria'], 'falta_causa': act['nombre'], 'cantidad': act['cantidad'], 'fecha': d['fecha'], 'hora': d['hora'], 'leido': 0});
      }
    }
    return {'success': true};
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    if (_u == null) return {'success': false};
    final db = await database;
    final idF = '${_u!.cargo}_${_u!.id}';
    final m = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) as t FROM actividad WHERE id_end=? AND tipo=?', [idF, 'merito']);
    final d = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) as t FROM actividad WHERE id_end=? AND tipo=?', [idF, 'demerito']);
    final ult = await db.rawQuery("SELECT a.*, CASE WHEN a.id_star LIKE 'estudiante_%' THEN (SELECT nombre||' '||apellidos FROM estudiante WHERE id=SUBSTR(a.id_star, INSTR(a.id_star,'_')+1)) WHEN a.id_star LIKE 'profesor_%' THEN (SELECT nombre||' '||apellidos FROM profesor WHERE id=SUBSTR(a.id_star, INSTR(a.id_star,'_')+1)) ELSE 'Sistema' END as notificador FROM actividad a WHERE a.id_end=? ORDER BY a.fecha DESC, a.hora DESC LIMIT 20", [idF]);
    return {'success': true, 'stats': {'meritos': (m.first['t'] as int?)??0, 'demeritos': (d.first['t'] as int?)??0}, 'ultimas_actividades': ult};
  }

  static Future<Map<String, dynamic>> verificarNotificador(String n, String p) async {
    final db = await database;
    final partes = n.trim().split(' ');
    final nom = partes.isNotEmpty ? partes[0] : '';
    final ap = partes.length > 1 ? partes.sublist(1).join(' ') : '';
    for (final t in ['estudiante', 'profesor', 'oficial', 'directiva']) {
      final r = await db.query(t, where: 'nombre=? AND apellidos=? AND password=?', whereArgs: [nom, ap, p], limit: 1);
      if (r.isNotEmpty) return {'success': true, 'id': r.first['id'], 'nombre': '${r.first['nombre']} ${r.first['apellidos']}', 'cargo': t};
    }
    return {'success': false};
  }
}
