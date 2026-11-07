import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: acceso, teclado y validación sin conexión', (
    tester,
  ) async {
    app.main();
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.text('INICIAR SESIÓN').evaluate().isNotEmpty) break;
    }
    expect(find.widgetWithText(TextField, 'Usuario'), findsOneWidget);
    await tester.ensureVisible(find.text('INICIAR SESIÓN'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('INICIAR SESIÓN'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Ingresa usuario y contraseña'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
