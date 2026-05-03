// ============================================
// SERVICIO DE API - COMUNICACION CON BACKEND
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';

class ApiService {
  static String? _token;
  static Usuario? _usuario;

  // ============================================
  // GETTERS
  // ============================================
  static String? get token => _token;
  static Usuario? get usuario => _usuario;
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ============================================
  // INICIALIZAR SESION DESDE ALMACENAMIENTO
  // ============================================
  static Future<bool> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final usuarioJson = prefs.getString('usuario');

    if (_token != null && usuarioJson != null) {
      _usuario = Usuario.fromJson(jsonDecode(usuarioJson));
      return true;
    }
    return false;
  }

  // ============================================
  // GUARDAR SESION
  // ============================================
  static Future<void> saveSession(String token, Usuario usuario) async {
    _token = token;
    _usuario = usuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('usuario', jsonEncode(usuario.toJson()));
  }

  // ============================================
  // CERRAR SESION
  // ============================================
  static Future<void> logout() async {
    _token = null;
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ============================================
  // HEADERS
  // ============================================
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'EMCC-App/1.0',
      };

  // ============================================
  // COOKIE DE INFINITYFREE
  // ============================================
  static String? _infinityCookie;

  static Future<void> _obtenerCookie() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}login.php?i=1');
      final response = await http.get(uri, headers: {
        'User-Agent': 'EMCC-App/1.0',
      });
      
      // Extraer cookie __test
      final setCookie = response.headers['set-cookie'];
      if (setCookie != null) {
        final match = RegExp(r'__test=([^;]+)').firstMatch(setCookie);
        if (match != null) {
          _infinityCookie = '__test=${match.group(1)}';
        }
      }
    } catch (e) {
      // Si no se puede obtener cookie, continuar sin ella
    }
  }

  // ============================================
  // POST GENERICO (CORREGIDO CON COOKIE)
  // ============================================
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      // Obtener cookie si no existe
      if (_infinityCookie == null) {
        await _obtenerCookie();
      }

      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      // Headers con cookie
      final postHeaders = Map<String, String>.from(headers);
      if (_infinityCookie != null) {
        postHeaders['Cookie'] = _infinityCookie!;
      }

      final response = await http.post(
        url,
        headers: postHeaders,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      // Si falló por cookie, reintentar
      if (response.statusCode == 403 || response.statusCode == 503) {
        _infinityCookie = null;
        await _obtenerCookie();
        return await post(endpoint, data);
      }
      
      return {
        'success': false,
        'message': 'Error del servidor: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexion: $e',
      };
    }
  }
  // ============================================
  // LOGIN
  // ============================================
  static Future<Map<String, dynamic>> login(
    String nombre,
    String apellidos,
    String password,
    String cargo,
  ) async {
    final response = await post(ApiConfig.loginEndpoint, {
      'nombre': nombre,
      'apellidos': apellidos,
      'password': password,
      'cargo': cargo,
    });

    if (response['success'] == true) {
      final usuario = Usuario.fromJson(response['usuario']);
      await saveSession(response['token'], usuario);
    }

    return response;
  }

  // ============================================
  // VERIFICAR TOKEN
  // ============================================
  static Future<bool> verificarToken() async {
    if (_token == null) return false;
    final response = await post(ApiConfig.verificarTokenEndpoint, {
      'token': _token,
    });
    return response['valid'] == true;
  }

  // ============================================
  // DATOS DEL DASHBOARD
  // ============================================
  static Future<Map<String, dynamic>> getDashboard() async {
    return await post(ApiConfig.dashboardEndpoint, {
      'token': _token,
    });
  }

  // ============================================
  // BUSCAR ESTUDIANTES
  // ============================================
  static Future<List<dynamic>> buscarEstudiantes(String query) async {
    try {
      // Obtener cookie si no existe
      if (_infinityCookie == null) {
        await _obtenerCookie();
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.buscarEndpoint}&q=${Uri.encodeComponent(query)}&token=${_token ?? ''}');
      
      final getHeaders = Map<String, String>.from(headers);
      if (_infinityCookie != null) {
        getHeaders['Cookie'] = _infinityCookie!;
      }

      final response = await http.get(url, headers: getHeaders);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['resultados'] != null) {
          return decoded['resultados'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // OBTENER CATALOGOS
  // ============================================
  static Future<List<dynamic>> getCatalogo(String tipo) async {
    try {
      // Obtener cookie si no existe
      if (_infinityCookie == null) {
        await _obtenerCookie();
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.catalogoEndpoint}&tipo=$tipo&token=${_token ?? ''}');
      
      final getHeaders = Map<String, String>.from(headers);
      if (_infinityCookie != null) {
        getHeaders['Cookie'] = _infinityCookie!;
      }

      final response = await http.get(url, headers: getHeaders);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['resultados'] != null) {
          return decoded['resultados'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============================================
  // ENVIAR NOTIFICACION
  // ============================================
  static Future<Map<String, dynamic>> enviarNotificacion(
      Map<String, dynamic> data) async {
    data['token'] = _token;
    return await post(ApiConfig.notificarEndpoint, data);
  }

  // ============================================
  // OBTENER PERFIL
  // ============================================
  static Future<Map<String, dynamic>> getPerfil() async {
    return await post(ApiConfig.perfilEndpoint, {
      'token': _token,
    });
  }

  // ============================================
  // VERIFICAR CUENTA TEMPORAL
  // ============================================
  static Future<Map<String, dynamic>> verificarNotificador(
      String nombre, String password) async {
    return await post(ApiConfig.verificarNotificadorEndpoint, {
      'nombre': nombre,
      'password': password,
      'token': _token,
    });
  }
}