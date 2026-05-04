import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
    return await openDatabase(path, version: 2, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    final String sql = await rootBundle.loadString('assets/data/usuario_use.sql');
    final statements = sql.split(';');
    for (final stmt in statements) {
      final trimmed = stmt.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('--') && !trimmed.startsWith('/*')) {
        try { await db.execute(trimmed); } catch (e) {
          print('SQL Error: $e');
        }
      }
    }
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
      String tabla;
      switch (cargo) {
        case 'estudiante': tabla = 'estudiante'; break;
        case 'profesor': tabla = 'profesor'; break;
        case 'oficial': tabla = 'oficial'; break;
        case 'directiva': tabla = 'directiva'; break;
        default: return {'success': false, 'message': 'Cargo no válido'};
      }
      
      print('🔍 Buscando en tabla: $tabla');
      print('🔍 Nombre: $nombre, Apellidos: $apellidos, Password: $password');
      
      // Primero verificar si la tabla tiene datos
      final count = await db.rawQuery('SELECT COUNT(*) as c FROM $tabla');
      print('🔍 Registros en $tabla: ${count.first['c']}');
      
      // Buscar usuario
      final resultados = await db.query(
        tabla,
        where: 'nombre = ? AND apellidos = ? AND password = ?',
        whereArgs: [nombre, apellidos, password],
        limit: 1,
      );
      
      print('🔍 Resultados encontrados: ${resultados.length}');
      
      if (resultados.isNotEmpty) {
        final u = resultados.first;
        print('✅ Usuario encontrado: ${u['nombre']} ${u['apellidos']}');
        final usuario = Usuario(
          id: u['id'] is int ? u['id'] as int : int.tryParse(u['id'].toString()) ?? 0,
          nombre: u['nombre'].toString(),
          apellidos: u['apellidos'].toString(),
          ci: (u['CI'] ?? u['ci'] ?? '').toString(),
          cargo: cargo,
          ocupacion: u['ocupacion']?.toString(),
          grado: u['grado']?.toString(),
          peloton: u['peloton'] is int ? u['peloton'] as int : int.tryParse(u['peloton'].toString()),
        );
        await saveSession(usuario);
        return {'success': true, 'usuario': usuario.toJson()};
      }
      
      print('❌ Usuario no encontrado');
      return {'success': false, 'message': 'Usuario no encontrado'};
    } catch (e) {
      print('💥 ERROR en login: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    return await db.rawQuery(
      "SELECT e.*, COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end = 'estudiante_' || e.id AND tipo = 'merito'), 0) as meritos, COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end = 'estudiante_' || e.id AND tipo = 'demerito'), 0) as demeritos FROM estudiante e WHERE e.nombre LIKE ? OR e.apellidos LIKE ? OR e.CI LIKE ? LIMIT 30",
      [searchTerm, searchTerm, searchTerm],
    );
  }

  static Future<List<Map<String, dynamic>>> getCatalogo(String tipo) async {
    final db = await database;
    final tabla = tipo == 'merito' ? 'meritos' : 'demeritos';
    return await db.query(tabla, orderBy: 'id');
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final db = await database;
    if (_usuario == null) return {'success': false};
    final idF = '${_usuario!.cargo}_${_usuario!.id}';
    final hoy = DateTime.now();
    final dias = hoy.weekday >= 3 ? hoy.weekday - 3 : hoy.weekday + 4;
    final inicio = hoy.subtract(Duration(days: dias)).toString().split(' ')[0];
    final m = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) as t FROM actividad WHERE id_end=? AND tipo=? AND fecha>=?', [idF, 'merito', inicio]);
    final d = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) as t FROM actividad WHERE id_end=? AND tipo=? AND fecha>=?', [idF, 'demerito', inicio]);
    final act = await db.query('actividad', where: 'id_end=? AND fecha>=?', whereArgs: [idF, inicio], orderBy: 'fecha DESC, hora DESC');
    final mVal = (m.first['t'] as int?) ?? 0;
    final dVal = (d.first['t'] as int?) ?? 0;
    return {'success': true, 'stats': {'meritos_semana': mVal, 'demeritos_semana': dVal, 'balance_semana': mVal - dVal}, 'semana_actual': act, 'semana_fecha': inicio, 'alarma_activa': false};
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

  static Future<Map<String, dynamic>> getPerfil() async {
    final db = await database;
    if (_usuario == null) return {'success': false};
    final idF = '${_usuario!.cargo}_${_usuario!.id}';
    final m = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) as t FROM actividad WHERE id_end=? AND tipo=?', [idF, 'merito']);
    final d = await db.rawQuery('SELECT COALESCE(SUM(cantidad),0) as t FROM actividad WHERE id_end=? AND tipo=?', [idF, 'demerito']);
    final ult = await db.query('actividad', where: 'id_end=?', whereArgs: [idF], orderBy: 'fecha DESC, hora DESC', limit: 20);
    return {'success': true, 'stats': {'meritos': (m.first['t'] as int?) ?? 0, 'demeritos': (d.first['t'] as int?) ?? 0}, 'ultimas_actividades': ult};
  }

  static Future<Map<String, dynamic>> verificarNotificador(String nombre, String password) async {
    final db = await database;
    final p = nombre.trim().split(' ');
    final nom = p.isNotEmpty ? p[0] : '';
    final ap = p.length > 1 ? p.sublist(1).join(' ') : '';
    for (final t in ['estudiante', 'profesor', 'oficial', 'directiva']) {
      final r = await db.query(t, where: 'nombre=? AND apellidos=? AND password=?', whereArgs: [nom, ap, password], limit: 1);
      if (r.isNotEmpty) return {'success': true, 'id': r.first['id'], 'nombre': '${r.first['nombre']} ${r.first['apellidos']}', 'cargo': t};
    }
    return {'success': false};
  }
}
