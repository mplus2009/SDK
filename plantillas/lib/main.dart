import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/database_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  try {
    await DatabaseService.database;
    await DatabaseService.initSession();
  } catch (e) {
    debugPrint('ERROR al iniciar BD: $e');
  }
  
  runApp(const SistemaEscolarApp());
}

class SistemaEscolarApp extends StatelessWidget {
  const SistemaEscolarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMCC Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1E3C72),
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E3C72), foregroundColor: Colors.white, elevation: 0),
      ),
      home: const SplashScreen(),
    );
  }
}
