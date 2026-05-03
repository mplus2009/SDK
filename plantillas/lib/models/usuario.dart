// ============================================
// MODELO DE USUARIO
// ============================================

class Usuario {
  final int id;
  final String nombre;
  final String apellidos;
  final String ci;
  final String cargo;
  final String? ocupacion;
  final String? grado;
  final int? peloton;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.ci,
    required this.cargo,
    this.ocupacion,
    this.grado,
    this.peloton,
  });

  String get nombreCompleto => '$nombre $apellidos';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      apellidos: json['apellidos'] ?? '',
      ci: json['ci'] ?? '',
      cargo: json['cargo'] ?? 'estudiante',
      ocupacion: json['ocupacion'],
      grado: json['grado'],
      peloton: json['peloton'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'ci': ci,
      'cargo': cargo,
      'ocupacion': ocupacion,
      'grado': grado,
      'peloton': peloton,
    };
  }
}