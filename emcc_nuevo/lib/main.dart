import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/database_service.dart';
import 'services/mesh_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EMCCApp());
}

class EMCCApp extends StatelessWidget {
  const EMCCApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMCC Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primaryColor: const Color(0xFF1E3C72)),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    // Iniciar el servidor mesh PRIMERO
    try {
      await MeshService().startServer();
    } catch (_) {}
    
    // Cargar base de datos
    try {
      await DatabaseService.database;
      await DatabaseService.initSession();
    } catch (_) {}
    
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => DatabaseService.isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
