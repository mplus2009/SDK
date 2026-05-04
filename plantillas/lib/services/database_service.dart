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
        try { await db.execute(trimmed); } catch (e) {}
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
    final db = await database;
    String tabla;
    switch (cargo) {
      case 'estudiante': tabla = 'estudiante'; break;
      case 'profesor': tabla = 'profesor'; break;
      case 'oficial': tabla = 'oficial'; break;
      case 'directiva': tabla = 'directiva'; break;
      default: return {'success': false, 'message': 'Cargo no válido'};
    }
    final resultados = await db.query(tabla, where: 'nombre = ? AND apellidos = ? AND password = ?', whereArgs: [nombre, apellidos, password], limit: 1);
    if (resultados.isNotEmpty) {
      final user = resultados.first;
      final usuario = Usuario(id: user['id'] as int, nombre: user['nombre'] as String, apellidos: user['apellidos'] as String, ci: user['CI'] as String? ?? user['ci'] as String? ?? '', cargo: cargo, ocupacion: user['ocupacion'] as String?, grado: user['grado'] as String?, peloton: user['peloton'] as int?);
      await saveSession(usuario);
      return {'success': true, 'usuario': usuario.toJson()};
    }
    return {'success': false, 'message': 'Usuario no encontrado'};
  }

  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    return await db.rawQuery("SELECT e.*, COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end = 'estudiante_' || e.id AND tipo = 'merito'), 0) as meritos, COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end = 'estudiante_' || e.id AND tipo = 'demerito'), 0) as demeritos FROM estudiante e WHERE e.nombre LIKE ? OR e.apellidos LIKE ? OR e.CI LIKE ? ORDER BY e.apellidos, e.nombre LIMIT 30", [searchTerm, searchTerm, searchTerm]);
  }

  static Future<List<Map<String, dynamic>>> getCatalogo(String tipo) async {
    final db = await database;
    final tabla = tipo == 'merito' ? 'meritos' : 'demeritos';
    return await db.query(tabla, orderBy: 'categoria, id');
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final db = await database;
    final usuario = _usuario;
    if (usuario == null) return {'success': false, 'message': 'No hay sesión'};
    final idFormateado = '${usuario.cargo}_${usuario.id}';
    final hoy = DateTime.now();
    final diasHastaMiercoles = hoy.weekday >= 3 ? hoy.weekday - 3 : hoy.weekday + 4;
    final inicioSemana = hoy.subtract(Duration(days: diasHastaMiercoles));
    final inicioSemanaStr = inicioSemana.toString().split(' ')[0];
    
    final meritosSemana = await db.rawQuery('SELECT COALESCE(SUM(cantidad), 0) as total FROM actividad WHERE id_end = ? AND tipo = ? AND fecha >= ?', [idFormateado, 'merito', inicioSemanaStr]);
    final demeritosSemana = await db.rawQuery('SELECT COALESCE(SUM(cantidad), 0) as total FROM actividad WHERE id_end = ? AND tipo = ? AND fecha >= ?', [idFormateado, 'demerito', inicioSemanaStr]);
    final meritoTotal = meritosSemana.first['total'] as int? ?? 0;
    final demeritoTotal = demeritosSemana.first['total'] as int? ?? 0;
    
    final nuevasCount = await db.rawQuery('SELECT COUNT(*) as total FROM actividad WHERE id_end = ? AND leido = 0', [idFormateado]);
    final nuevas = nuevasCount.first['total'] as int? ?? 0;
    
    final actividades = await db.query('actividad', where: 'id_end = ? AND fecha >= ?', whereArgs: [idFormateado, inicioSemanaStr], orderBy: 'fecha DESC, hora DESC');
    
    final semanasAnteriores = await db.rawQuery("SELECT fecha, COUNT(*) as total FROM actividad WHERE id_end = ? AND fecha < ? GROUP BY strftime('%Y-%W', fecha) ORDER BY fecha DESC LIMIT 4", [idFormateado, inicioSemanaStr]);
    
    // Alarma
    bool alarmaActiva = false;
    if (usuario.cargo == 'estudiante') {
      final gradoEst = usuario.grado ?? '10mo';
      final limites = {'10mo': 15, '11no': 11, '12mo': 10};
      final limite = limites[gradoEst] ?? 15;
      alarmaActiva = demeritoTotal >= limite;
    }
    
    return {
      'success': true, 'usuario': usuario.toJson(),
      'stats': {'meritos_semana': meritoTotal, 'demeritos_semana': demeritoTotal, 'balance_semana': meritoTotal - demeritoTotal},
      'semana_actual': actividades, 'semana_fecha': inicioSemanaStr,
      'semanas_anteriores': semanasAnteriores, 'nuevas_actividades': nuevas,
      'alarma_activa': alarmaActiva,
    };
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    final db = await database;
    final usuario = _usuario;
    if (usuario == null) return {'success': false, 'message': 'No hay sesión'};
    final idFormateado = '${usuario.cargo}_${usuario.id}';
    final meritos = await db.rawQuery('SELECT COALESCE(SUM(cantidad), 0) as total FROM actividad WHERE id_end = ? AND tipo = ?', [idFormateado, 'merito']);
    final demeritos = await db.rawQuery('SELECT COALESCE(SUM(cantidad), 0) as total FROM actividad WHERE id_end = ? AND tipo = ?', [idFormateado, 'demerito']);
    final ultimas = await db.query('actividad', where: 'id_end = ?', whereArgs: [idFormateado], orderBy: 'fecha DESC, hora DESC', limit: 20);
    final meritosCat = await db.rawQuery('SELECT categoria, SUM(cantidad) as total FROM actividad WHERE id_end = ? AND tipo = ? GROUP BY categoria ORDER BY total DESC', [idFormateado, 'merito']);
    final demeritosCat = await db.rawQuery('SELECT categoria, SUM(cantidad) as total FROM actividad WHERE id_end = ? AND tipo = ? GROUP BY categoria ORDER BY total DESC', [idFormateado, 'demerito']);
    return {'success': true, 'perfil': usuario.toJson(), 'stats': {'meritos': meritos.first['total'] ?? 0, 'demeritos': demeritos.first['total'] ?? 0}, 'ultimas_actividades': ultimas, 'meritos_por_categoria': meritosCat, 'demeritos_por_categoria': demeritosCat};
  }

  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> data) async {
    final db = await database;
    final destinatarios = data['destinatarios'] as List<dynamic>;
    final actividades = data['actividades'] as List<dynamic>;
    final fecha = data['fecha'] as String;
    final hora = data['hora'] as String;
    final observaciones = data['observaciones'] as String? ?? '';
    final idStar = data['id_star'] as String;
    final cargoNotificador = data['cargo_notificador'] as String;
    final idStarFormateado = '${cargoNotificador}_$idStar';
    int insertados = 0;
    for (final dest in destinatarios) {
      final idEndFormateado = 'estudiante_${dest['id']}';
      for (final act in actividades) {
        await db.insert('actividad', {'id_star': idStarFormateado, 'id_end': idEndFormateado, 'tipo': act['tipo'], 'categoria': act['categoria'], 'falta_causa': act['nombre'], 'cantidad': act['cantidad'], 'fecha': fecha, 'hora': hora, 'observaciones': observaciones, 'leido': 0});
        insertados++;
      }
    }
    return {'success': true, 'message': '$insertados actividades registradas'};
  }

  static Future<Map<String, dynamic>> verificarNotificador(String nombre, String password) async {
    final db = await database;
    final partes = nombre.trim().split(' ');
    final nom = partes.isNotEmpty ? partes[0] : '';
    final apell = partes.length > 1 ? partes.sublist(1).join(' ') : '';
    for (final tabla in ['estudiante', 'profesor', 'oficial', 'directiva']) {
      final results = await db.query(tabla, where: 'nombre = ? AND apellidos = ? AND password = ?', whereArgs: [nom, apell, password], limit: 1);
      if (results.isNotEmpty) {
        final user = results.first;
        return {'success': true, 'id': user['id'], 'nombre': '${user['nombre']} ${user['apellidos']}', 'cargo': tabla};
      }
    }
    return {'success': false, 'message': 'Credenciales incorrectas'};
  }
}
