import 'package:flutter/material.dart';
import 'dart:async';
import '../services/database_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    Timer(const Duration(milliseconds: 2500), () => _verificarSesion());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verificarSesion() async {
    try {
      final sesionActiva = DatabaseService.isLoggedIn;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => sesionActiva ? const DashboardScreen() : const LoginScreen()));
    } catch (e) {
      setState(() => _error = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => _verificarSesion(), child: const Text('Reintentar')),
            ]),
          ),
        ),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1e3c72), Color(0xFF2a5298)])),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(30)), child: const Icon(Icons.school_rounded, size: 70, color: Colors.white)),
                  const SizedBox(height: 30),
                  const Text('EMCC DIGITAL', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Text('Sistema de Gestión Escolar', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), letterSpacing: 1)),
                  const SizedBox(height: 50),
                  SizedBox(width: 40, height: 40, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)), strokeWidth: 3)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;
  const AnimatedBuilder({super.key, required this.animation, required this.builder});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(animation: animation, builder: builder);
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  const AnimatedBuilder2({super.key, required Animation<double> animation, required this.builder}) : super(listenable: animation);
  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return builder(context, null);
  }
}
