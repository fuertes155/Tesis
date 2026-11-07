// Recorrido del paciente y del evaluador antes de las pruebas: bienvenida,
// consentimiento, selección de pruebas, nueva sesión, login y reportes.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

void main() {
  group('bienvenida del paciente', () {
    testWidgets('sin consentimiento, COMENZAR lleva a firmarlo', (tester) async {
      final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'user');
      await irA(tester, c, '/patient_welcome');
      await tocar(tester, find.text('COMENZAR AHORA'));
      expect(rutaActual(c), '/consent');
    });

    testWidgets('con consentimiento va directo a las pruebas', (tester) async {
      final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'user');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('consent_accepted', true);
      await irA(tester, c, '/patient_welcome');
      expect(rutaActual(c), '/test_selector');
    });

    testWidgets('si firmó mientras estaba en la bienvenida, COMENZAR va a las pruebas', (tester) async {
      final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'user');
      await irA(tester, c, '/patient_welcome');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('consent_accepted', true);
      await tocar(tester, find.text('COMENZAR AHORA'));
      expect(rutaActual(c), '/test_selector');
    });

    testWidgets('se puede restablecer el consentimiento', (tester) async {
      final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'user');
      await irA(tester, c, '/patient_welcome');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('consent_accepted', true);
      await tocar(tester, find.textContaining('Restablecer'));
      expect(find.text('Consentimiento restablecido'), findsOneWidget);
      expect(prefs.getBool('consent_accepted'), isNull);
    });
  });

  group('selector de pruebas', () {
    Future<ProviderContainer> abrir(WidgetTester tester, {List<String>? iniciales}) async {
      final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
          rolConSesion: 'doctor', pacienteActual: 21);
      await irA(tester, c, '/home');
      c.read(routerProvider).push('/test_selector',
          extra: iniciales == null ? null : {'initialSelection': iniciales});
      await esperar(tester);
      return c;
    }

    testWidgets('sin pruebas elegidas no se puede comenzar', (tester) async {
      final c = await abrir(tester);
      expect(find.text('SELECCIONA AL MENOS UNA PRUEBA'), findsOneWidget);
      await tocar(tester, find.text('SELECCIONA AL MENOS UNA PRUEBA'));
      expect(rutaActual(c), '/test_selector');
    });

    testWidgets('elegir todas las pruebas arma el protocolo en orden', (tester) async {
      final c = await abrir(tester);
      for (final prueba in [
        'Prueba de Memoria Visual',
        'Prueba de Atención Sostenida',
        'Prueba de Fluidez Verbal',
        'Prueba de Funciones Ejecutivas (Stroop)',
      ]) {
        await tocar(tester, find.text(prueba));
      }
      expect(find.text('COMENZAR EVALUACIÓN  (~26 min)'), findsOneWidget);
      // Tocar de nuevo una prueba la quita.
      await tocar(tester, find.text('Prueba de Fluidez Verbal'));
      expect(find.text('COMENZAR EVALUACIÓN  (~21 min)'), findsOneWidget);
      await tocar(tester, find.text('Prueba de Fluidez Verbal'));
      expect(find.text('COMENZAR EVALUACIÓN  (~26 min)'), findsOneWidget);

      await tocar(tester, find.text('COMENZAR EVALUACIÓN  (~26 min)'), pasos: 5);
      expect(rutaActual(c), '/game_flow');
      await esperar(tester, pasos: 20); // la batería abre la primera prueba
      expect(find.text('Memoria Visual (1/4)'), findsOneWidget);
    });

    testWidgets('una selección inicial desconocida no cuenta como prueba', (tester) async {
      await abrir(tester, iniciales: ['Prueba de Memoria Visual', 'Prueba inexistente']);
      expect(find.text('COMENZAR EVALUACIÓN  (~8 min)'), findsOneWidget);
    });
  });

  group('nueva sesión', () {
    testWidgets('en el teléfono los protocolos se apilan y Personalizar abre el selector', (tester) async {
      final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]),
          rolConSesion: 'doctor', pantalla: const Size(420, 900));
      await irA(tester, c, '/home');
      c.read(routerProvider).push('/new_session', extra: 21);
      await esperar(tester);
      expect(tester.takeException(), isNull);
      // La lista se construye a medida que se desplaza.
      final lista = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down);
      await tester.scrollUntilVisible(find.text('Personalizar'), 300, scrollable: lista.last);
      await tocar(tester, find.text('Personalizar'));
      expect(rutaActual(c), '/test_selector');
    });

    testWidgets('las tarjetas reaccionan al mouse', (tester) async {
      final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]), rolConSesion: 'doctor');
      await irA(tester, c, '/new_session', extra: {'patientId': '21'});
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Protocolo integral')));
      await tester.pump(const Duration(milliseconds: 300));
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Protocolo integral'), findsOneWidget);
    });
  });

  group('inicio de sesión', () {
    testWidgets('el paciente entra a su bienvenida; Intro pasa de campo y envía', (tester) async {
      final servidor = ServidorSimulado(usuarios: [ServidorSimulado.paciente]);
      final c = await montarApp(tester, servidor);
      await tester.enterText(find.widgetWithText(TextField, 'Usuario'), 'paciente@gmail.com');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), ServidorSimulado.clave);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await esperar(tester);
      expect(rutaActual(c), '/patient_welcome');
    });

    testWidgets('se puede ver la contraseña e ir a restablecerla', (tester) async {
      final c = await montarApp(tester, ServidorSimulado());
      final campo = find.widgetWithText(TextField, 'Contraseña');
      expect(tester.widget<TextField>(campo).obscureText, isTrue);
      await tocar(tester, find.descendant(of: campo, matching: find.byType(IconButton)));
      expect(tester.widget<TextField>(campo).obscureText, isFalse);

      await tocar(tester, find.textContaining('Olvidaste'));
      expect(rutaActual(c), '/reset_password');
    });
  });

  testWidgets('si fallan los reportes lo informa', (tester) async {
    final c = await montarApp(tester, ServidorSimulado()..fallar('GET /evaluacion/reportes'), rolConSesion: 'doctor');
    await irA(tester, c, '/report_preview');
    expect(find.textContaining('Error al cargar reportes'), findsOneWidget);
  });

  testWidgets('la pantalla de prueba simulada lleva a resultados', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'doctor');
    await irA(tester, c, '/test_placeholder');
    await tocar(tester, find.text('Finalizar Prueba (Simulación)'));
    expect(rutaActual(c), '/results');
  });
}
