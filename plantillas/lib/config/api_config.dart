class ApiConfig {
  // URL con parámetro para evitar el bloqueo de InfinityFree
  static const String baseUrl = 'https://tarjetadereporte.infinityfree.me/api/';
  
  // Endpoints con el parámetro ?i=1
  static const String loginEndpoint = 'login.php?i=1';
  static const String verificarTokenEndpoint = 'verificar_token.php?i=1';
  static const String dashboardEndpoint = 'dashboard.php?i=1';
  static const String buscarEndpoint = 'buscar.php?i=1';
  static const String catalogoEndpoint = 'catalogo.php?i=1';
  static const String estudianteEndpoint = 'estudiante.php?i=1';
  static const String notificarEndpoint = 'notificar.php?i=1';
  static const String perfilEndpoint = 'perfil.php?i=1';
  static const String verificarNotificadorEndpoint = 'verificar_notificador.php?i=1';
  
  static const int colorPrimary = 0xFF1E3C72;
  static const int colorMerito = 0xFF10B981;
  static const int colorDemerito = 0xFFEF4444;
  static const int colorBackground = 0xFFF0F4F8;
}