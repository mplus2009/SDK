import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/database_service.dart';
import 'services/permission_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // Pedir permisos
  await PermissionService.requestAllPermissions();
  
  // Iniciar BD
  await DatabaseService.database;
  await DatabaseService.initSession();
  
  runApp(const EMCCApp());
}

class EMCCApp extends StatelessWidget {
  const EMCCApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMCC Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3C72),
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E3C72), foregroundColor: Colors.white),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _scale = Tween<double>(begin: 0.8, end: 1).animate(_controller);
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DatabaseService.isLoggedIn ? const DashboardScreen() : const LoginScreen()));
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1e3c72), Color(0xFF2a5298)])),
        child: Center(
          child: FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(25)), child: const Icon(Icons.school, size: 60, color: Colors.white)),
            const SizedBox(height: 30),
            const Text('EMCC DIGITAL', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ]))),
        ),
      ),
    );
  }
}
