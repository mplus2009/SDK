import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/usuario.dart';

class ApiService {
  static String? _token;
  static Usuario? _usuario;

  static String? get token => _token;
  static Usuario? get usuario => _usuario;
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static Future<bool> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final json = prefs.getString('usuario');
    if (_token != null && json != null) {
      _usuario = Usuario.fromJson(jsonDecode(json));
      return true;
    }
    return false;
  }

  static Future<void> saveSession(String token, Usuario usuario) async {
    _token = token;
    _usuario = usuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('usuario', jsonEncode(usuario.toJson()));
  }

  static Future<void> logout() async {
    _token = null;
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final response = await http.post(url, headers: headers, body: jsonEncode(data));
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexion'};
    }
  }

  static Future<Map<String, dynamic>> login(String nombre, String apellidos, String password, String cargo) async {
    final response = await post(ApiConfig.loginEndpoint, {
      'nombre': nombre, 'apellidos': apellidos, 'password': password, 'cargo': cargo,
    });
    if (response['success'] == true) {
      final usuario = Usuario.fromJson(response['usuario']);
      await saveSession(response['token'], usuario);
    }
    return response;
  }

  static Future<bool> verificarToken() async {
    if (_token == null) return false;
    final response = await post(ApiConfig.verificarTokenEndpoint, {'token': _token});
    return response['valid'] == true;
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    return await post(ApiConfig.dashboardEndpoint, {'token': _token});
  }

  static Future<List<dynamic>> buscarEstudiantes(String query) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.buscarEndpoint}?q=${Uri.encodeComponent(query)}&token=${_token ?? ''}');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['resultados'] != null) return decoded['resultados'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getCatalogo(String tipo) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.catalogoEndpoint}?tipo=$tipo&token=${_token ?? ''}');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['resultados'] != null) return decoded['resultados'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> data) async {
    data['token'] = _token;
    return await post(ApiConfig.notificarEndpoint, data);
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    return await post(ApiConfig.perfilEndpoint, {'token': _token});
  }

  static Future<Map<String, dynamic>> verificarNotificador(String nombre, String password) async {
    return await post(ApiConfig.verificarNotificadorEndpoint, {
      'nombre': nombre, 'password': password, 'token': _token,
    });
  }
}