import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await DatabaseService.database;
    await DatabaseService.initSession();
  } catch (e) {
    debugPrint('Error BD: $e');
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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      if (!mounted) return;
      if (DatabaseService.isLoggedIn) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () { setState(() => _error = null); _iniciar(); }, child: const Text('Reintentar')),
        ]))),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1e3c72), Color(0xFF2a5298)])),
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
