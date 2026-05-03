// ============================================
// PANTALLA DE LOGIN
// ============================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _passwordController = TextEditingController();
  String _cargo = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<Map<String, String>> _cargos = [
    {'value': 'directiva', 'label': 'Directiva'},
    {'value': 'oficial', 'label': 'Oficial'},
    {'value': 'profesor', 'label': 'Profesor'},
    {'value': 'estudiante', 'label': 'Estudiante'},
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================
  // PROBAR CONEXION
  // ============================================
  Future<void> _probarConexion() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('login.php', {'test': true});

      if (!mounted) return;

      if (response['success'] == true) {
        _showSnackBar('Conexion exitosa!', Colors.green);
      } else {
        _showSnackBar(
            response['message'] ?? 'Error de conexion', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: $e', Colors.red);
    }

    setState(() => _isLoading = false);
  }

  // ============================================
  // INICIAR SESION
  // ============================================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await ApiService.login(
      _nombreController.text.trim(),
      _apellidosController.text.trim(),
      _passwordController.text,
      _cargo,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      _showSnackBar(
        response['message'] ?? 'Error al iniciar sesion',
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 60,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ============================================
                    // HEADER
                    // ============================================
                    Column(
                      children: const [
                        Icon(
                          Icons.school,
                          size: 50,
                          color: Color(0xFF1E3C72),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Acceso',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3C72),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sistema de Gestion Escolar',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),

                    // ============================================
                    // BOTON QR (SIMULADO)
                    // ============================================
                    Container(
                      padding: const EdgeInsets.only(bottom: 25),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showSnackBar(
                                'Escanner QR en desarrollo', Colors.orange);
                          },
                          icon: const Icon(Icons.qr_code_scanner, size: 28),
                          label: const Text(
                            'Escanear QR para Iniciar Sesion',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3C72),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 8,
                            shadowColor:
                                const Color(0xFF1E3C72).withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // DIVISOR
                    // ============================================
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            'o ingresa manualmente',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // CAMPO NOMBRE
                    // ============================================
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ingresa tu nombre',
                        prefixIcon:
                            Icon(Icons.person, color: Color(0xFF2A5298)),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ============================================
                    // CAMPO APELLIDOS
                    // ============================================
                    TextFormField(
                      controller: _apellidosController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                        hintText: 'Ingresa tus apellidos',
                        prefixIcon:
                            Icon(Icons.people, color: Color(0xFF2A5298)),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tus apellidos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                                          // ============================================
                      // CAMPO CONTRASEÑA
                      // ============================================
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contrasena',
                          hintText: 'Ingresa tu contrasena',
                          prefixIcon:
                              const Icon(Icons.lock, color: Color(0xFF2A5298)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: const Color(0xFF2A5298),
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contrasena';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ============================================
                      // SELECTOR DE CARGO
                      // ============================================
                      DropdownButtonFormField<String>(
                        value: _cargo.isEmpty ? null : _cargo,
                        decoration: const InputDecoration(
                          labelText: 'Cargo',
                          prefixIcon: Icon(Icons.badge,
                              color: Color(0xFF2A5298)),
                        ),
                        hint: const Text('Selecciona tu cargo'),
                        items: _cargos.map((cargo) {
                          return DropdownMenuItem<String>(
                            value: cargo['value'],
                            child: Text(cargo['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _cargo = value ?? '');
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona tu cargo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // ============================================
                      // BOTON INICIAR SESION
                      // ============================================
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3C72),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Iniciar Sesion',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // ============================================
                      // BOTON PROBAR CONEXION
                      // ============================================
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _probarConexion,
                          icon: const Icon(Icons.wifi_find),
                          label: const Text('Probar conexion al servidor'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3C72),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ============================================
                      // INFO
                      // ============================================
                      const Text(
                        'Ingresa con tu nombre, apellidos y contrasena',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}