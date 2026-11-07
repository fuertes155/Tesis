// Ficha del paciente: sesiones recientes, acciones, eliminación (gestor),
// sincronización y estados sin datos.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_application_1/services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/plugins_simulados.dart';
import '../helpers/servidor_simulado.dart';

ServidorSimulado servidorFicha() => ServidorSimulado(
      pacientes: [
        pacienteEjemplo(),
        pacienteEjemplo(id: 28, nombre: 'Gloria Zuluaga', diagnostico: '', doctorId: null, documento: '25'),
      ],
      sesiones: [
        sesionEjemplo(id: 1, fecha: '2026-05-01T10:00:00'),
        sesionEjemplo(id: 2, fecha: '2026-09-16T10:00:00', estado: 'pending'),
        sesionEjemplo(id: 3, pacienteId: 30), // de un paciente que no está en la lista
      ],
      resultados: [
        ...bateriaEjemplo(21, '2026-09-16', [40, 45, 34, 37]),
        ...bateriaEjemplo(21, '2026-05-01', [50, 51, 40, 43]),
      ],
    );

Future<ProviderContainer> abrirFicha(WidgetTester tester, ServidorSimulado servidor,
    {Object? extra = const {'name': 'Paciente', 'id': 21}, String rol = 'doctor', Size pantalla = const Size(1440, 1000)}) async {
  final c = await montarApp(tester, servidor, rolConSesion: rol, pantalla: pantalla);
  await irA(tester, c, rol == 'gestor' ? '/users_admin' : '/home');
  servidor.peticiones.clear();
  c.read(routerProvider).push('/patient_detail', extra: extra);
  await esperar(tester);
  return c;
}

void main() {
  testWidgets('lista las sesiones recientes, de la más nueva a la más antigua', (tester) async {
    final c = await abrirFicha(tester, servidorFicha());
    expect(find.text('SESIONES RECIENTES'), findsOneWidget);
    final nueva = tester.getTopLeft(find.text('Sesión #2'));
    final vieja = tester.getTopLeft(find.text('Sesión #1'));
    expect(nueva.dy, lessThan(vieja.dy));
    expect(find.text('En Progreso'), findsOneWidget);
    expect(find.text('Sesión #3'), findsNothing); // es de otro paciente

    await tocar(tester, find.text('Sesión #1'));
    expect(rutaActual(c), '/results');
    expect(find.text('Resultados - Sesión #1'), findsOneWidget);
  });

  testWidgets('el detalle de la gráfica muestra dominio y porcentaje', (tester) async {
    await abrirFicha(tester, servidorFicha());
    final grafica = tester.widget<LineChart>(find.byType(LineChart));
    final linea = grafica.data.lineBarsData.first;
    final items = grafica.data.lineTouchData.touchTooltipData.getTooltipItems([
      LineBarSpot(linea, 0, linea.spots.first),
    ]);
    expect(items.single!.text, 'Memoria: 50%');
  });

  testWidgets('un paciente sin diagnóstico ni médico lo indica', (tester) async {
    await abrirFicha(tester, servidorFicha(), extra: {'name': 'Gloria', 'id': 28});
    expect(find.text('Sin asignar'), findsOneWidget);
    expect(find.text('Sin Evaluaciones'), findsOneWidget);
  });

  testWidgets('si el paciente no existe muestra el primero de la lista', (tester) async {
    await abrirFicha(tester, servidorFicha(), extra: {'name': 'Fantasma', 'id': '99'});
    expect(find.text('Jorge Enrique Salazar Mejía'), findsWidgets);
  });

  testWidgets('sin paciente indicado no carga datos', (tester) async {
    final servidor = servidorFicha();
    await abrirFicha(tester, servidor, extra: 'Sin datos');
    expect(servidor.recibio('GET', '/sessions/'), isFalse);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('si falla la carga deja de esperar', (tester) async {
    await abrirFicha(tester, servidorFicha()..fallar('GET /patients/'));
    expect(find.text('—'), findsWidgets);
    expect(find.text('Sin Evaluaciones'), findsOneWidget);
  });

  testWidgets('las acciones abren nueva sesión e historial', (tester) async {
    final c = await abrirFicha(tester, servidorFicha());
    await tocar(tester, find.text('Iniciar Sesión'));
    expect(rutaActual(c), '/new_session');
    c.read(routerProvider).pop();
    await esperar(tester);

    await tocar(tester, find.text('Ver Historial'));
    expect(rutaActual(c), '/history');
  });

  testWidgets('Sin Evaluaciones invita a iniciar la evaluación', (tester) async {
    final c = await abrirFicha(tester, servidorFicha(), extra: {'name': 'Gloria', 'id': 28});
    await tocar(tester, find.text('Iniciar Evaluación'));
    expect(rutaActual(c), '/new_session');
  });

  testWidgets('exporta el PDF con el último resultado o con un resumen general', (tester) async {
    Future<void> exportar(ImpresionSimulada impresion) async {
      await tocar(tester, find.text('Exportar PDF'));
      for (var i = 0; i < 60 && impresion.documentos.isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    final conResultados = ImpresionSimulada();
    await abrirFicha(tester, servidorFicha());
    await exportar(conResultados);
    expect(conResultados.documentos, hasLength(1));

    await tester.pumpWidget(const SizedBox());
    final sinResultados = ImpresionSimulada();
    await abrirFicha(tester, servidorFicha(), extra: {'name': 'Gloria', 'id': 28});
    await exportar(sinResultados);
    expect(sinResultados.documentos, hasLength(1));
  });

  testWidgets('sincronizar envía la cola local', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (args, sink) {}),
    );
    final c = await abrirFicha(tester, servidorFicha());
    await tocar(tester, find.byTooltip('Sincronizar Offline'));
    expect(find.text('Sincronizando datos locales...'), findsOneWidget);
    c.invalidate(syncServiceProvider); // detiene su temporizador periódico
    await tester.pump();
  });

  testWidgets('la flecha vuelve a la pantalla anterior (vista de teléfono y de escritorio)', (tester) async {
    var c = await abrirFicha(tester, servidorFicha(), pantalla: const Size(500, 900));
    await tocar(tester, find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    expect(rutaActual(c), '/home');

    await tester.pumpWidget(const SizedBox());
    c = await abrirFicha(tester, servidorFicha());
    await tocar(tester, find.byIcon(Icons.arrow_back_ios_new_rounded).first);
    expect(rutaActual(c), '/home');
  });

  group('eliminar (gestor)', () {
    testWidgets('el doctor no ve la opción', (tester) async {
      await abrirFicha(tester, servidorFicha());
      expect(find.byTooltip('Eliminar Paciente'), findsNothing);
    });

    testWidgets('advierte cuántas sesiones se borran; cancelar no elimina', (tester) async {
      final servidor = servidorFicha();
      await abrirFicha(tester, servidor, rol: 'gestor');
      await tocar(tester, find.byTooltip('Eliminar Paciente'));
      expect(find.textContaining('y 2 sesión(es) asociada(s)'), findsOneWidget);
      await tocar(tester, find.text('CANCELAR'));
      expect(servidor.recibio('DELETE', '/patients/21'), isFalse);
    });

    testWidgets('confirmar elimina y vuelve', (tester) async {
      final servidor = servidorFicha();
      final c = await abrirFicha(tester, servidor, rol: 'gestor');
      await tocar(tester, find.byTooltip('Eliminar Paciente'));
      await tocar(tester, find.text('ELIMINAR'));
      expect(servidor.recibio('DELETE', '/patients/21'), isTrue);
      expect(find.text('Paciente eliminado correctamente'), findsOneWidget);
      expect(rutaActual(c), '/users_admin');
    });

    testWidgets('sin conteo de sesiones avisa igual; si falla lo informa', (tester) async {
      final servidor = servidorFicha()
        ..fallar('GET /sessions/count')
        ..fallar('DELETE /patients/21', estado: 403);
      await abrirFicha(tester, servidor, rol: 'gestor');
      servidor.fallar('GET /sessions/');
      await tocar(tester, find.byTooltip('Eliminar Paciente'));
      expect(find.textContaining('Esta acción es permanente'), findsOneWidget);
      expect(find.textContaining('sesión(es)'), findsNothing);
      await tocar(tester, find.text('ELIMINAR'));
      expect(find.textContaining('No se pudo eliminar'), findsOneWidget);
    });
  });
}
