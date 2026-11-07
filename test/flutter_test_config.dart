import 'dart:async';

import 'package:flutter_application_1/router.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/plugins_simulados.dart';

/// Configuración común de todas las pruebas de `test/`.
///
/// Precarga las pantallas diferidas fuera del reloj simulado de testWidgets.
/// Si la primera carga ocurriera dentro de una prueba, el Future quedaría
/// ligado a esa prueba y las siguientes se quedarían esperando para siempre.
/// Por la misma razón se crea aquí el plugin de impresión.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(precargarPantallas);
  setUpAll(prepararImpresion);
  await testMain();
}
