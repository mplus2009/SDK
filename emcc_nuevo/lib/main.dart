import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1E3C72),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E3C72), foregroundColor: Colors.white, elevation: 0),
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
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fade = Tween(begin: 0.0, end: 1.0).animate(_ctrl);
    _scale = Tween(begin: 0.8, end: 1.0).animate(_ctrl);
    _ctrl.forward();
    _iniciar();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _iniciar() async {
    try {
      await DatabaseService.database;
      await DatabaseService.initSession();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (DatabaseService.isLoggedIn) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)])),
        child: Center(
          child: FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(25)), child: const Icon(Icons.school, size: 60, color: Colors.white)),
            const SizedBox(height: 30),
            const Text('EMCC DIGITAL', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            const Text('Cargando...', style: TextStyle(color: Colors.white70)),
          ]))),
        ),
      ),
    );
  }
}
