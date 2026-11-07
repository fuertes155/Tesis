import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

Future<void> ingresar(WidgetTester tester, String usuario, String clave) async {
  await tester.enterText(find.widgetWithText(TextField, 'Usuario'), usuario);
  await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), clave);
  await tocar(tester, find.text('INICIAR SESIÓN'));
}

void main() {
  testWidgets('muestra el formulario de inicio de sesión', (tester) async {
    final c = await montarApp(tester, ServidorSimulado());
    expect(rutaActual(c), '/');
    expect(find.widgetWithText(TextField, 'Usuario'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Contraseña'), findsOneWidget);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });

  testWidgets('con campos vacíos avisa y no llama al servidor', (tester) async {
    final servidor = ServidorSimulado();
    await montarApp(tester, servidor);
    await tocar(tester, find.text('INICIAR SESIÓN'));
    expect(find.text('Ingresa usuario y contraseña'), findsOneWidget);
    expect(servidor.recibio('POST', '/users/auth/login'), isFalse);
  });

  testWidgets('con clave incorrecta muestra el error del servidor y no navega', (tester) async {
    final c = await montarApp(tester, ServidorSimulado());
    await ingresar(tester, 'samuel@gmail.com', 'Incorrecta1');
    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
    expect(rutaActual(c), '/');
  });

  testWidgets('el doctor entra al inicio', (tester) async {
    final servidor = ServidorSimulado();
    final c = await montarApp(tester, servidor);
    await ingresar(tester, 'samuel@gmail.com', ServidorSimulado.clave);
    expect(servidor.recibio('POST', '/users/auth/login'), isTrue);
    expect(rutaActual(c), '/home');
  });

  testWidgets('el gestor entra a la administración de usuarios', (tester) async {
    final c = await montarApp(tester, ServidorSimulado());
    await ingresar(tester, 'samuel1@gmail.com', ServidorSimulado.clave);
    expect(rutaActual(c), '/users_admin');
  });

  testWidgets('si el servidor exige 2FA pasa a la verificación', (tester) async {
    final c = await montarApp(tester, ServidorSimulado()..exigir2fa = true);
    await ingresar(tester, 'samuel@gmail.com', ServidorSimulado.clave);
    expect(rutaActual(c), '/mfa');
  });
}
