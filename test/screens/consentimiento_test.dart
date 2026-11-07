// Consentimiento informado: solo se confirma tras aceptar los términos.
import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

Future<ProviderContainer> abrir(WidgetTester tester) async {
  final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'doctor');
  await irA(tester, c, '/home');
  c.read(routerProvider).push('/consent');
  await esperar(tester);
  return c;
}

// FilledButton.icon crea una subclase: se busca por "es un FilledButton".
final _confirmar = find.ancestor(
  of: find.text('CONFIRMAR Y CONTINUAR'),
  matching: find.byWidgetPredicate((w) => w is FilledButton),
);

void main() {
  testWidgets('muestra las cinco secciones del documento', (tester) async {
    await abrir(tester);
    for (final titulo in ['Autorización', 'Confidencialidad', 'Propósito', 'Revocabilidad', 'Efectos']) {
      expect(find.text(titulo), findsOneWidget);
    }
    expect(find.textContaining('comité de ética'), findsOneWidget);
  });

  testWidgets('sin aceptar no se puede confirmar; aceptar dos veces lo desmarca', (tester) async {
    await abrir(tester);
    expect(tester.widget<FilledButton>(_confirmar).onPressed, isNull);

    await tocar(tester, find.textContaining('He leído y acepto', findRichText: true));
    expect(tester.widget<FilledButton>(_confirmar).onPressed, isNotNull);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tocar(tester, find.textContaining('He leído y acepto', findRichText: true));
    expect(tester.widget<FilledButton>(_confirmar).onPressed, isNull);
  });

  testWidgets('al confirmar guarda la aceptación y vuelve', (tester) async {
    final c = await abrir(tester);
    await tocar(tester, find.textContaining('He leído y acepto', findRichText: true));
    await tocar(tester, _confirmar);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('consent_accepted'), isTrue);
    expect(rutaActual(c), '/home');
    expect(find.text('Consentimiento firmado exitosamente'), findsOneWidget);
  });

  testWidgets('la flecha vuelve sin firmar', (tester) async {
    final c = await abrir(tester);
    await tocar(tester, find.byIcon(Icons.arrow_back_rounded));
    expect(rutaActual(c), '/home');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('consent_accepted'), isNull);
  });
}
