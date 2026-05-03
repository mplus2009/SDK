import 'package:flutter/material.dart';

class NotificarVariables {
  final List<Map<String, dynamic>> destinatarios = [];
  final List<Map<String, dynamic>> actividadesAgregadas = [];
  List<dynamic> catalogoMeritos = [];
  List<dynamic> catalogoDemeritos = [];
  String tipoActual = 'merito';
  dynamic actividadSeleccionada;
  bool isLoading = true;
  bool enviando = false;
  bool usandoCuentaTemporal = false;
  String notificadorNombre = '';
  String notificadorCargo = '';
  int idStar = 0;
  String tipoNotificador = 'cuenta';
  String cargoNotificador = '';
  final buscarController = TextEditingController();
  final fechaController = TextEditingController();
  final horaController = TextEditingController();
  final observacionesController = TextEditingController();
  final tempNombreController = TextEditingController();
  final tempPasswordController = TextEditingController();
  final cantidadController = TextEditingController(text: '1');
  double slider10mo = 1;
  double slider11_12 = 1;
  int sliderMin10mo = 1, sliderMax10mo = 3;
  int sliderMin11_12 = 1, sliderMax11_12 = 3;
  List<dynamic> resultadosBusqueda = [];
  List<dynamic> resultadosActividad = [];
  String? categoriaFiltro;

  void dispose() {
    buscarController.dispose();
    fechaController.dispose();
    horaController.dispose();
    observacionesController.dispose();
    tempNombreController.dispose();
    tempPasswordController.dispose();
    cantidadController.dispose();
  }
}
