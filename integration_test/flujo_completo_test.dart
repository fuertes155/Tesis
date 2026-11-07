// Prueba de extremo a extremo (E2E): la app real en Chrome contra un backend de
// pruebas con su propia base de datos (lo levanta scripts/run_e2e.ps1).
//
// Flujo: login → Pacientes → ficha con evolución (I12) → Reportes → informe y
// PDF (I13) → nueva sesión → prueba de Fluidez Verbal → informe generado.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const api = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8001');
const paciente = 'Elena Ruiz Prueba E2E';
const doctor = 'samuel@gmail.com';
const clave = 'Password123!';

/// Espera (en tiempo real) a que aparezca un elemento: la app hace llamadas
/// HTTP reales, así que no se puede adelantar el reloj como en los widgets.
Future<void> esperarA(WidgetTester tester, Finder elemento, {int segundos = 30}) async {
  final limite = DateTime.now().add(Duration(seconds: segundos));
  while (DateTime.now().isBefore(limite)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (elemento.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  final visibles = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
      .where((s) => s.trim().isNotEmpty)
      .take(60)
      .join(' | ');
  fail('No apareció en $segundos s: $elemento | En pantalla: $visibles');
}

/// Deja correr la app en tiempo real (animaciones, desplazamientos, red).
Future<void> asentar(WidgetTester tester, {int ms = 600}) async {
  for (var t = 0; t < ms; t += 100) {
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

/// Toca como una persona: espera a que el elemento exista, lo desplaza a la
/// vista, deja que el desplazamiento termine (Flutter ignora toques sobre una
/// lista en movimiento) y mantiene el dedo unos milisegundos.
Future<void> tocar(WidgetTester tester, Finder elemento, {int segundos = 30}) async {
  await esperarA(tester, elemento, segundos: segundos);
  // Al centro de la pantalla: en el borde superior quedaría bajo la cabecera fija.
  await Scrollable.ensureVisible(tester.element(elemento.first), alignment: 0.5);
  await asentar(tester);
  final dedo = await tester.startGesture(tester.getCenter(elemento.first));
  await Future<void>.delayed(const Duration(milliseconds: 80));
  await dedo.up();
  await asentar(tester, ms: 300);
}

/// Cuenta los informes guardados en el backend para el paciente de prueba.
Future<int> informesEnBackend() async {
  final cliente = Dio(BaseOptions(baseUrl: '$api/api/v1'));
  final login = await cliente.post('/users/auth/login', data: {'username': doctor, 'password': clave});
  cliente.options.headers['Authorization'] = 'Bearer ${login.data['access_token']}';
  final pacientes = (await cliente.get('/patients/')).data as List;
  final id = pacientes.firstWhere((p) => p['name'] == paciente)['id'];
  return ((await cliente.get('/evaluacion/reportes/$id')).data as List).length;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flujo clínico completo: login → ficha → informe → evaluación → nuevo informe', (tester) async {
    final informesAntes = await informesEnBackend();
    app.main();

    // 1. Inicio de sesión del doctor
    await esperarA(tester, find.text('INICIAR SESIÓN'));
    await tester.enterText(find.widgetWithText(TextField, 'Usuario'), doctor);
    await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), clave);
    await tocar(tester, find.text('INICIAR SESIÓN'));

    // 2. Inicio → Pacientes → ficha del paciente
    await tocar(tester, find.text('Ver lista, buscar y editar perfiles'));
    await tocar(tester, find.text(paciente));

    // 3. I12: ficha con datos clínicos y gráfica de evolución
    await esperarA(tester, find.text('EVOLUCIÓN COGNITIVA'));
    expect(find.text('Deterioro cognitivo leve (amnésico)'), findsOneWidget);
    expect(find.text('72 años'), findsOneWidget);
    for (final dominio in ['Memoria', 'Atención', 'Funciones ejecutivas', 'Lenguaje']) {
      expect(find.text(dominio), findsOneWidget);
    }

    // 4. I13: reportes del paciente → informe con opción de PDF
    await tocar(tester, find.text('Reportes'));
    await tocar(tester, find.text('Reporte Cognitivo'));
    await esperarA(tester, find.text('Informe neuropsicológico'));
    expect(find.text('Descargar PDF'), findsOneWidget);
    expect(find.textContaining('Deterioro cognitivo leve'), findsWidgets);

    // Volver a la ficha
    await tocar(tester, find.byTooltip('Volver'));
    await esperarA(tester, find.text('Reportes del paciente'));
    await tester.pageBack();
    await esperarA(tester, find.text('EVOLUCIÓN COGNITIVA'));

    // 5. Nueva sesión desde la ficha: el paciente viene fijado
    await tocar(tester, find.text('Iniciar Sesión'));
    await esperarA(tester, find.text('¿Qué evaluación vas a aplicar?'));
    expect(find.text(paciente), findsOneWidget);
    await tocar(tester, find.text('Screening rápido'));

    // 6. En el selector se cambia Memoria Visual por Fluidez Verbal y se aplica
    await tocar(tester, find.text('Prueba de Memoria Visual'));
    await tocar(tester, find.text('Prueba de Fluidez Verbal'));
    await tocar(tester, find.textContaining('COMENZAR EVALUACIÓN'));
    await tocar(tester, find.text('Elegir tipo de prueba'));
    await tocar(tester, find.text('Semántica'));
    for (var i = 0; i < 8; i++) {
      await tocar(tester, find.byIcon(Icons.add));
    }
    await tocar(tester, find.text('Finalizar Ahora'));
    await esperarA(tester, find.text('Palabras generadas: 8'));
    await tocar(tester, find.text('Finalizar'));

    // 7. El backend genera el informe con el resultado recién obtenido
    await esperarA(tester, find.text('Informe neuropsicológico'), segundos: 60);
    await esperarA(tester, find.textContaining('MOTIVO DE EVALUACIÓN'));
    expect(find.textContaining(paciente), findsWidgets);
    expect(find.text('Fluidez Verbal'), findsWidgets);
    expect(find.text('Descargar PDF'), findsOneWidget);

    // 8. Y quedó guardado en el backend
    expect(await informesEnBackend(), informesAntes + 1);
  });
}
