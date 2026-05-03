// ============================================
// DATABASE_SERVICE.DART - CARGA DESDE SQL
// ============================================

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
    // Cargar el archivo SQL
    final String sql = await rootBundle.loadString('assets/data/usuario_use.sql');
    
    // Dividir por instrucciones SQL
    final statements = _splitSQL(sql);
    
    for (final stmt in statements) {
      final trimmed = stmt.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('--') && !trimmed.startsWith('/*')) {
        try {
          await db.execute(trimmed);
        } catch (e) {
          print('Error ejecutando SQL: ${trimmed.substring(0, 100)}... - $e');
        }
      }
    }
  }

  // ============================================
  // DIVIDIR ARCHIVO SQL EN INSTRUCCIONES
  // ============================================
  static List<String> _splitSQL(String sql) {
    final statements = <String>[];
    final buffer = StringBuffer();
    bool inString = false;
    String? stringChar;

    for (int i = 0; i < sql.length; i++) {
      final char = sql[i];

      // Detectar inicio/fin de string
      if (!inString && (char == "'" || char == '"')) {
        inString = true;
        stringChar = char;
      } else if (inString && char == stringChar) {
        // Verificar que no sea escape
        if (i + 1 < sql.length && sql[i + 1] == stringChar) {
          buffer.write(char);
          i++; // Saltar el siguiente
          continue;
        }
        inString = false;
        stringChar = null;
      }

      buffer.write(char);

      // Fin de instrucción
      if (!inString && char == ';') {
        statements.add(buffer.toString());
        buffer.clear();
      }
    }

    // Última instrucción si no termina con ;
    if (buffer.isNotEmpty) {
      statements.add(buffer.toString());
    }

    return statements;
  }
    // ============================================
  // MANEJO DE SESIÓN
  // ============================================
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

  // ============================================
  // LOGIN LOCAL
  // ============================================
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
    return {'success': false, 'message': 'Usuario no encontrado o contraseña incorrecta'};
  }

  // ============================================
  // BUSCAR ESTUDIANTES
  // ============================================
  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String query) async {
    final db = await database;
    final searchTerm = '%$query%';
    return await db.rawQuery("SELECT e.*, COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end = 'estudiante_' || e.id AND tipo = 'merito'), 0) as meritos, COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end = 'estudiante_' || e.id AND tipo = 'demerito'), 0) as demeritos FROM estudiante e WHERE e.nombre LIKE ? OR e.apellidos LIKE ? OR e.CI LIKE ? ORDER BY e.apellidos, e.nombre LIMIT 30", [searchTerm, searchTerm, searchTerm]);
  }

  // ============================================
  // OBTENER CATÁLOGO
  // ============================================
  static Future<List<Map<String, dynamic>>> getCatalogo(String tipo) async {
    final db = await database;
    final tabla = tipo == 'merito' ? 'meritos' : 'demeritos';
    return await db.query(tabla, orderBy: 'categoria, id');
  }

  // ============================================
  // OBTENER DASHBOARD
  // ============================================
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
    final actividades = await db.query('actividad', where: 'id_end = ? AND fecha >= ?', whereArgs: [idFormateado, inicioSemanaStr], orderBy: 'fecha DESC, hora DESC');
    return {'success': true, 'usuario': usuario.toJson(), 'stats': {'meritos_semana': meritoTotal, 'demeritos_semana': demeritoTotal, 'balance_semana': meritoTotal - demeritoTotal}, 'semana_actual': actividades, 'semana_fecha': inicioSemanaStr, 'alarma_activa': false};
  }

  // ============================================
  // ENVIAR NOTIFICACIÓN
  // ============================================
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

  // ============================================
  // OBTENER PERFIL
  // ============================================
  static Future<Map<String, dynamic>> getPerfil() async {
    final db = await database;
    final usuario = _usuario;
    if (usuario == null) return {'success': false, 'message': 'No hay sesión'};
    final idFormateado = '${usuario.cargo}_${usuario.id}';
    final meritos = await db.rawQuery('SELECT COALESCE(SUM(cantidad), 0) as total FROM actividad WHERE id_end = ? AND tipo = ?', [idFormateado, 'merito']);
    final demeritos = await db.rawQuery('SELECT COALESCE(SUM(cantidad), 0) as total FROM actividad WHERE id_end = ? AND tipo = ?', [idFormateado, 'demerito']);
    final ultimas = await db.query('actividad', where: 'id_end = ?', whereArgs: [idFormateado], orderBy: 'fecha DESC, hora DESC', limit: 20);
    return {'success': true, 'perfil': usuario.toJson(), 'stats': {'meritos': meritos.first['total'] ?? 0, 'demeritos': demeritos.first['total'] ?? 0}, 'ultimas_actividades': ultimas};
  }

  // ============================================
  // VERIFICAR NOTIFICADOR TEMPORAL
  // ============================================
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