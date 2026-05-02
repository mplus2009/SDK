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
      };

  // ============================================
  // POST GENERICO
  // ============================================
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexion: $e',
      };
    }
  }

  // ============================================
  // GET GENERICO
  // ============================================
  static Future<Map<String, dynamic>> get(String endpoint,
      {Map<String, String>? params}) async {
    try {
      var url = '${ApiConfig.baseUrl}$endpoint';
      if (params != null) {
        url += '?${Uri(queryParameters: params).query}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
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
    final response = await get(
      ApiConfig.buscarEndpoint,
      params: {'q': query, 'token': _token ?? ''},
    );
    if (response is List) return response;
    return [];
  }

  // ============================================
  // OBTENER CATALOGOS
  // ============================================
  static Future<List<dynamic>> getCatalogo(String tipo) async {
    final response = await get(
      ApiConfig.catalogoEndpoint,
      params: {'tipo': tipo, 'token': _token ?? ''},
    );
    if (response is List) return response;
    return [];
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