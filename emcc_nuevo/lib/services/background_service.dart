import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class BackgroundService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static Timer? _syncTimer;

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(initSettings, onDidReceiveNotificationResponse: (response) {
      _handleNotificationTap(response.payload);
    });
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart, autoStart: true, isForegroundMode: true,
        notificationChannelId: 'emcc_notifications',
        initialNotificationTitle: 'EMCC Digital',
        initialNotificationContent: 'Sistema de gestión escolar activo',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(autoStart: true, onForeground: _onStart, onBackground: _onIosBackground),
    );
    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<void> _onStart(ServiceInstance service) async {
    final db = await DatabaseService.database;
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _checkNewActivities(db, service);
    });
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  static Future<void> _checkNewActivities(Database db, ServiceInstance service) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimoId = prefs.getInt('ultimo_id_actividad') ?? 0;
      final usuarioJson = prefs.getString('usuario');
      if (usuarioJson == null) return;
      final usuario = jsonDecode(usuarioJson);
      final idFormateado = '${usuario['cargo']}_${usuario['id']}';
      final nuevas = await db.query('actividad', where: 'id_end = ? AND id > ? AND leido = 0', whereArgs: [idFormateado, ultimoId], orderBy: 'id DESC', limit: 5);
      if (nuevas.isNotEmpty) {
        final nuevoUltimoId = nuevas.first['id'] as int;
        await prefs.setInt('ultimo_id_actividad', nuevoUltimoId);
        for (final act in nuevas) {
          await _showNotification(act);
        }
      }
    } catch (e) {
      print('Error verificando actividades: $e');
    }
  }

  static Future<void> _showNotification(Map<String, dynamic> actividad) async {
    final esMerito = actividad['tipo'] == 'merito';
    final titulo = esMerito ? 'Nuevo Mérito' : 'Nuevo Demérito';
    final cuerpo = '${actividad['falta_causa']} - ${esMerito ? '+' : '-'}${actividad['cantidad']} punto(s)';
    const androidDetails = AndroidNotificationDetails('emcc_notifications', 'EMCC Notificaciones', channelDescription: 'Notificaciones de méritos y deméritos', importance: Importance.high, priority: Priority.high, showWhen: true);
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(actividad['id'] as int, titulo, cuerpo, details, payload: jsonEncode(actividad));
  }

  static void _handleNotificationTap(String? payload) {
    if (payload != null) {
      print('Usuario tocó notificación: $payload');
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    return true;
  }
}