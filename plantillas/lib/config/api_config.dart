// ============================================
// CONFIGURACION DE LA API
// ============================================

class ApiConfig {
  // CAMBIAR: URL de tu servidor backend
  // Para desarrollo local (emulador Android):
  static const String baseUrl = 'http://10.0.2.2:8000/api/';
  
  // Para dispositivo real en misma red WiFi:
  // static const String baseUrl = 'http://192.168.1.100:8000/api/';
  
  // Para producción (InfinityFree):
  // static const String baseUrl = 'https://tarjetadereporte.infinityfree.me/api/';
  
  // Endpoints
  static const String loginEndpoint = 'login.php';
  static const String verificarTokenEndpoint = 'verificar_token.php';
  static const String dashboardEndpoint = 'dashboard.php';
  static const String buscarEndpoint = 'buscar.php';
  static const String catalogoEndpoint = 'catalogo.php';
  static const String estudianteEndpoint = 'estudiante.php';
  static const String notificarEndpoint = 'notificar.php';
  static const String perfilEndpoint = 'perfil.php';
  static const String cambiarPasswordEndpoint = 'cambiar_password.php';
  static const String misNotificacionesEndpoint = 'mis_notificaciones.php';
  static const String checkNuevasEndpoint = 'check_nuevas.php';
  static const String verificarNotificadorEndpoint = 'verificar_notificador.php';
  
  // Colores de la app
  static const int colorPrimary = 0xFF1E3C72;
  static const int colorSecondary = 0xFF2A5298;
  static const int colorMerito = 0xFF10B981;
  static const int colorDemerito = 0xFFEF4444;
  static const int colorBackground = 0xFFF0F4F8;
  static const int colorCard = 0xFFFFFFFF;
}