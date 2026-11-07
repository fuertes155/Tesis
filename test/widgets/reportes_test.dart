// I13 — Informe neuropsicológico generado y vista previa del PDF (RF3, RF9, HU04).
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

ServidorSimulado servidorConReportes() => ServidorSimulado(
      pacientes: [pacienteEjemplo(), pacienteEjemplo(id: 28, nombre: 'Gloria Patricia Zuluaga Henao')],
      reportes: [
        reporteEjemplo(),
        reporteEjemplo(id: 8, pacienteId: 28, nombre: 'Gloria Patricia Zuluaga Henao', fecha: '2026-11-03'),
      ],
    );

void main() {
  testWidgets('desde Inicio lista los informes de todos los pacientes', (tester) async {
    final servidor = servidorConReportes();
    final c = await montarApp(tester, servidor, rolConSesion: 'doctor');
    await irA(tester, c, '/report_preview');

    expect(find.text('Historial de Reportes'), findsOneWidget);
    expect(servidor.recibio('GET', '/evaluacion/reportes'), isTrue);
    expect(find.text('Paciente: Jorge Enrique Salazar Mejía'), findsOneWidget);
    expect(find.text('Paciente: Gloria Patricia Zuluaga Henao'), findsOneWidget);
  });

  testWidgets('para un paciente lista solo sus informes', (tester) async {
    final c = await montarApp(tester, servidorConReportes(), rolConSesion: 'doctor');
    await irA(tester, c, '/report_preview', extra: {'patientId': 28, 'patientName': 'Gloria Patricia Zuluaga Henao'});

    expect(find.text('Reportes del paciente'), findsOneWidget);
    expect(find.text('Gloria Patricia Zuluaga Henao'), findsOneWidget); // subtítulo
    expect(find.text('Paciente: Gloria Patricia Zuluaga Henao'), findsOneWidget);
    expect(find.text('Paciente: Jorge Enrique Salazar Mejía'), findsNothing);
  });

  testWidgets('un paciente sin informes ve el mensaje vacío', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(pacientes: [pacienteEjemplo()]), rolConSesion: 'doctor');
    await irA(tester, c, '/report_preview', extra: {'patientId': 21});
    expect(find.text('Este paciente aún no tiene reportes generados'), findsOneWidget);
  });

  testWidgets('si no hay ningún informe lo indica', (tester) async {
    final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'doctor');
    await irA(tester, c, '/report_preview');
    expect(find.text('No hay reportes generados aún'), findsOneWidget);
  });

  testWidgets('al abrir un informe se ve completo y con la opción de PDF', (tester) async {
    final c = await montarApp(tester, servidorConReportes(), rolConSesion: 'doctor');
    await irA(tester, c, '/report_preview', extra: {'patientId': 21});

    await tocar(tester, find.text('Reporte Cognitivo'), pasos: 40);

    expect(rutaActual(c), '/reporte_cognitivo');
    expect(find.text('Informe neuropsicológico'), findsOneWidget);
    expect(find.text('Descargar PDF'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.textContaining('Jorge Enrique Salazar Mejía'), findsWidgets);
    expect(find.textContaining('Deterioro cognitivo mayor probable'), findsOneWidget);
    expect(find.textContaining('Reevaluación neuropsicológica sugerida en 3 meses'), findsOneWidget);
  });

  testWidgets('el paciente (rol user) no puede ver el historial de informes', (tester) async {
    final c = await montarApp(tester, servidorConReportes(), rolConSesion: 'user');
    await irA(tester, c, '/report_preview');
    expect(rutaActual(c), '/patient_welcome');
  });
}
