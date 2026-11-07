// Alta de paciente (rol gestor): validación, consentimiento, edad a partir
// de la fecha de nacimiento y manejo de errores.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

Future<ProviderContainer> abrirFormulario(WidgetTester tester, ServidorSimulado servidor) async {
  final c = await montarApp(tester, servidor, rolConSesion: 'gestor');
  await irA(tester, c, '/users_admin');
  c.read(routerProvider).push('/create_patient');
  await esperar(tester);
  return c;
}

Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

Future<void> marcarConsentimiento(WidgetTester tester) => tocar(tester, find.text('Consentimiento Informado'));

void main() {
  testWidgets('el nombre es obligatorio', (tester) async {
    final servidor = ServidorSimulado();
    await abrirFormulario(tester, servidor);
    expect(find.text('Información del\nPaciente'), findsOneWidget);

    await tocar(tester, find.text('Crear Expediente'));
    expect(find.text('Requerido'), findsOneWidget);
    expect(servidor.recibio('POST', '/patients/'), isFalse);
  });

  testWidgets('sin consentimiento no crea el expediente', (tester) async {
    final servidor = ServidorSimulado();
    await abrirFormulario(tester, servidor);
    await tester.enterText(campo('Nombre Completo'), 'Ana Gómez');
    await tocar(tester, find.text('Crear Expediente'));
    expect(find.text('Debe aceptar el consentimiento informado.'), findsOneWidget);
    expect(servidor.recibio('POST', '/patients/'), isFalse);
  });

  testWidgets('crea el expediente con la edad calculada y vuelve atrás', (tester) async {
    final servidor = ServidorSimulado();
    final c = await abrirFormulario(tester, servidor);

    await tester.enterText(campo('Nombre Completo'), 'Ana Gómez');
    await tocar(tester, campo('Fecha de Nacimiento'), pasos: 5);
    await tocar(tester, find.text('OK'), pasos: 5); // fecha propuesta: hace ~30 años
    await tester.enterText(campo('Cédula / Documento de Identidad'), '1020');
    await tester.enterText(campo('Teléfono'), '3001234567');
    await tester.enterText(campo('Correo Electrónico (Opcional)'), 'ana@x.com');
    await tester.enterText(campo('Institución'), 'Clínica San José');
    await tester.enterText(campo('Antecedentes'), 'Hipertensión');
    await marcarConsentimiento(tester);
    await tocar(tester, find.text('Crear Expediente'));

    expect(find.text('¡Éxito!'), findsOneWidget);
    final enviado = servidor.cuerpos['POST /patients/'] as Map;
    expect(enviado['name'], 'Ana Gómez');
    expect(enviado['age'], inInclusiveRange(29, 30));
    // Se muestra dd/mm/aaaa pero se envía en ISO, que es lo que la app sabe leer.
    expect(enviado['birth_date'], matches(RegExp(r'^\d{4}-\d\d-\d\d$')));
    expect(enviado['document_id'], '1020');
    expect(enviado['institution'], 'Clínica San José');
    expect(enviado['has_consent'], isTrue);
    expect(enviado['diagnosis'], 'Pendiente');

    await tocar(tester, find.text('Entendido'));
    expect(rutaActual(c), '/users_admin');
  });

  testWidgets('sin fecha de nacimiento la edad queda en 0; cancelar el calendario no cambia nada',
      (tester) async {
    final servidor = ServidorSimulado();
    await abrirFormulario(tester, servidor);
    await tester.enterText(campo('Nombre Completo'), 'Sin Fecha');
    await tocar(tester, campo('Fecha de Nacimiento'), pasos: 5);
    await tocar(tester, find.text('Cancel'), pasos: 5);
    await marcarConsentimiento(tester);
    await tocar(tester, find.text('Crear Expediente'));
    expect((servidor.cuerpos['POST /patients/'] as Map)['age'], 0);
    expect((servidor.cuerpos['POST /patients/'] as Map)['birth_date'], isNull);
    await tocar(tester, find.text('Entendido'));
  });

  testWidgets('mientras guarda muestra el progreso y luego el error', (tester) async {
    final servidor = ServidorSimulado()..fallar('POST /patients/', estado: 409, cuerpo: {'detail': 'Documento duplicado'});
    await abrirFormulario(tester, servidor);
    await tester.enterText(campo('Nombre Completo'), 'Ana Gómez');
    await marcarConsentimiento(tester);

    servidor.pausa = Completer<void>();
    await tocar(tester, find.text('Crear Expediente'), pasos: 2);
    expect(find.text('Creando expediente...'), findsOneWidget);
    servidor.pausa!.complete();
    servidor.pausa = null;
    await esperar(tester);

    expect(find.textContaining('Error al crear paciente'), findsOneWidget);
    expect(find.textContaining('Documento duplicado'), findsOneWidget);
    expect(find.text('Crear Expediente'), findsOneWidget);
  });
}
