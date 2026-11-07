// Panel del gestor: usuarios, médicos y pacientes (alta, edición, baja,
// disponibilidad y asignación de médico).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

final _doctora = <String, dynamic>{
  'id': 40, 'username': 'dra.ana@x.com', 'role': 'doctor', 'full_name': null, 'document_id': null,
  'is_active': true, 'is_available': false, 'registration_date': null,
};
final _admin2 = <String, dynamic>{
  'id': 24, 'username': 'admin2@x.com', 'role': 'gestor', 'full_name': 'Admin Dos', 'document_id': null,
  'is_active': false, 'is_available': true, 'registration_date': '2026-01-10T08:00:00',
};

ServidorSimulado servidorAdmin() => ServidorSimulado(
      usuarios: [Map.of(ServidorSimulado.doctor), Map.of(_doctora), Map.of(ServidorSimulado.gestor), Map.of(_admin2)],
      pacientes: [
        pacienteEjemplo(),
        pacienteEjemplo(id: 28, nombre: 'Gloria Zuluaga', doctorId: null, documento: '25172390')
          ..['phone'] = '3001112233',
      ],
    );

Future<ProviderContainer> abrirPanel(WidgetTester tester, ServidorSimulado servidor,
    {Size pantalla = const Size(1440, 1000)}) async {
  servidor.usuarioActual = ServidorSimulado.gestor;
  final c = await montarApp(tester, servidor, rolConSesion: 'gestor', pantalla: pantalla);
  await irA(tester, c, '/users_admin');
  return c;
}

/// Botón (por tooltip) dentro de la fila que contiene [texto].
Finder enFila(String texto, String tooltip) => find.descendant(
      of: find.ancestor(
        of: find.text(texto),
        matching: find.byWidgetPredicate(
            (w) => w is Container && w.padding == const EdgeInsets.symmetric(horizontal: 32, vertical: 24)),
      ),
      matching: find.byTooltip(tooltip),
    );

void main() {
  testWidgets('resume usuarios y muestra las tres tablas', (tester) async {
    await abrirPanel(tester, servidorAdmin());

    expect(find.text('Panel de Administrador'), findsOneWidget);
    expect(find.text('Médicos'), findsOneWidget);
    expect(find.text('Administradores del Sistema'), findsOneWidget);
    // Solo disponibles: la doctora ocupada no aparece al inicio.
    expect(find.text('Samuel Vanegas'), findsOneWidget);
    expect(find.text('dra.ana@x.com'), findsNothing);
    expect(find.text('DISPONIBLE'), findsOneWidget);
    // Pacientes: asignado y pendiente.
    expect(find.text('Jorge Enrique Salazar Mejía'), findsOneWidget);
    expect(find.text('ASIGNADO'), findsOneWidget);
    expect(find.text('PENDIENTE'), findsOneWidget);
    expect(find.text('Sin asignar'), findsOneWidget);
    expect(find.text('GZ'), findsOneWidget); // iniciales
    // Administradores: sin nombre se muestra el correo; inactivo.
    expect(find.text('samuel1@gmail.com'), findsWidgets);
    expect(find.text('INACTIVO'), findsOneWidget);
    expect(find.text('ACTIVO'), findsOneWidget);
    // DateFormat sin configuración regional: el mes sale en inglés (ver resumen).
    expect(find.text('10 Jan 2026'), findsOneWidget);
    expect(find.text('---'), findsNothing); // el gestor sin fecha no está en las tablas visibles
  });

  testWidgets('mientras carga muestra el esqueleto', (tester) async {
    final servidor = servidorAdmin()..usuarioActual = ServidorSimulado.gestor;
    final c = await montarApp(tester, servidor, rolConSesion: 'gestor');
    servidor.pausa = Completer<void>();
    await irA(tester, c, '/users_admin');
    expect(find.text('Panel de Administrador'), findsNothing);
    servidor.pausa!.complete();
    servidor.pausa = null;
    await esperar(tester);
    expect(find.text('Panel de Administrador'), findsOneWidget);
  });

  testWidgets('si falla la carga avisa', (tester) async {
    await abrirPanel(tester, servidorAdmin()..fallar('GET /users/'));
    expect(find.textContaining('Error al cargar datos'), findsOneWidget);
  });

  testWidgets('cambiar la disponibilidad de un médico lo saca de la lista de disponibles', (tester) async {
    final servidor = servidorAdmin();
    await abrirPanel(tester, servidor);

    await tocar(tester, enFila('Samuel Vanegas', 'Cambiar Disponibilidad'));
    expect(servidor.consultas['PUT /users/36/availability'], {'is_available': 'false'});
    await esperar(tester);
    expect(find.text('Samuel Vanegas'), findsNothing);
    expect(find.text('Sin Resultados'), findsOneWidget);

    // El filtro se puede desmarcar.
    await tocar(tester, find.text('Solo disponibles'));
    expect(tester.widget<FilterChip>(find.byType(FilterChip)).selected, isFalse);
  });

  testWidgets('un médico nuevo aparece en la tabla sin recargar la pantalla', (tester) async {
    final servidor = servidorAdmin();
    await abrirPanel(tester, servidor);
    servidor.usuarios.add({
      ...ServidorSimulado.doctor, 'id': 41, 'username': 'dr.luis@x.com', 'full_name': 'Luis Pardo',
    });
    await tocar(tester, find.byTooltip('Actualizar'));
    await esperar(tester);
    expect(find.text('Luis Pardo'), findsOneWidget);
    expect(find.text('LP'), findsOneWidget);
  });

  testWidgets('si el servidor rechaza el cambio de disponibilidad avisa', (tester) async {
    final servidor = servidorAdmin()..fallar('PUT /users/36/availability');
    await abrirPanel(tester, servidor);
    await tocar(tester, enFila('Samuel Vanegas', 'Cambiar Disponibilidad'));
    expect(find.textContaining('Error al actualizar disponibilidad'), findsOneWidget);
  });

  testWidgets('buscar sin coincidencias muestra la tabla vacía', (tester) async {
    await abrirPanel(tester, servidorAdmin());

    await tester.enterText(find.widgetWithText(TextField, 'Buscar médico...'), 'zzz');
    await tester.pump();
    expect(find.text('Sin Resultados'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Buscar médico...'), 'samuel');
    await tester.pump();
    expect(find.text('Sin Resultados'), findsNothing);

    final buscarPaciente = find.widgetWithText(TextField, 'Buscar paciente (nombre, teléfono, diagnóstico)...');
    await tester.enterText(buscarPaciente, 'xyz');
    await tester.pump();
    expect(find.text('Sin Resultados'), findsOneWidget);
    await tester.enterText(buscarPaciente, '300111');
    await tester.pump();
    expect(find.text('Sin Resultados'), findsNothing);
  });

  group('asignar médico', () {
    testWidgets('elige un médico disponible y lo asigna', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);

      await tocar(tester, enFila('Gloria Zuluaga', 'Asignar Médico'));
      expect(find.text('Asignar Médico'), findsWidgets);
      expect(find.text('dra.ana@x.com'), findsNothing); // ocupada: no se ofrece
      await tocar(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('samuel@gmail.com')));

      expect(servidor.consultas['PUT /patients/28/assign-doctor'], {'doctor_id': '36'});
      expect(servidor.veces('GET', '/patients/'), 2); // recarga los datos
    });

    testWidgets('cerrar el diálogo no asigna', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('Gloria Zuluaga', 'Asignar Médico'));
      await tester.tapAt(const Offset(10, 10));
      await esperar(tester);
      expect(servidor.recibio('PUT', '/patients/28/assign-doctor'), isFalse);
    });

    testWidgets('si falla la asignación avisa', (tester) async {
      final servidor = servidorAdmin()..fallar('PUT /patients/28/assign-doctor');
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('Gloria Zuluaga', 'Asignar Médico'));
      await tocar(tester, find.descendant(of: find.byType(AlertDialog), matching: find.text('samuel@gmail.com')));
      expect(find.textContaining('Error al asignar médico'), findsOneWidget);
    });

    testWidgets('sin médicos disponibles lo indica', (tester) async {
      final servidor = servidorAdmin();
      servidor.usuarios.first['is_available'] = false;
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('Gloria Zuluaga', 'Asignar Médico'));
      expect(find.text('No hay médicos disponibles'), findsOneWidget);
    });
  });

  group('nuevo usuario', () {
    Future<void> abrirDialogo(WidgetTester tester) async {
      await tocar(tester, find.text('Nuevo Usuario'));
      expect(find.text('Crear Nuevo Usuario'), findsOneWidget);
    }

    testWidgets('crea un gestor con nombre y documento', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);
      await abrirDialogo(tester);

      // Sin correo ni contraseña no hace nada.
      await tocar(tester, find.text('Crear usuario'));
      expect(servidor.recibio('POST', '/users/register'), isFalse);

      // El doctor (por defecto) se crea disponible.
      expect(find.text('¿Disponible inicialmente?'), findsOneWidget);
      await tocar(tester, find.byType(Switch));

      await tester.enterText(find.widgetWithText(TextField, 'Correo Electrónico'), 'nuevo@x.com');
      await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), 'Clave123!');
      await tester.enterText(find.widgetWithText(TextField, 'Nombre Completo'), 'Nuevo Gestor');
      await tester.enterText(find.widgetWithText(TextField, 'Cédula / Documento de Identidad'), ' 1020 ');
      await tocar(tester, find.text('Doctor'), pasos: 5);
      await tocar(tester, find.text('Administrador (Gestor)').last);
      expect(find.text('¿Disponible inicialmente?'), findsNothing);
      await tocar(tester, find.text('Crear usuario'));

      expect(find.text('Crear Nuevo Usuario'), findsNothing);
      final enviado = servidor.cuerpos['POST /users/register'] as Map;
      expect(enviado['role'], 'gestor');
      expect(enviado['full_name'], 'Nuevo Gestor');
      expect(enviado['document_id'], '1020');
      expect(find.text('Nuevo Gestor'), findsOneWidget);
    });

    testWidgets('sin nombre ni documento los envía vacíos', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);
      await abrirDialogo(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Correo Electrónico'), 'dr@x.com');
      await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), 'Clave123!');
      await tocar(tester, find.text('Crear usuario'));
      final enviado = servidor.cuerpos['POST /users/register'] as Map;
      expect(enviado['full_name'], isNull);
      expect(enviado['document_id'], isNull);
      expect(enviado['role'], 'doctor');
    });

    testWidgets('un correo repetido muestra el error y deja el diálogo abierto', (tester) async {
      await abrirPanel(tester, servidorAdmin());
      await abrirDialogo(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Correo Electrónico'), 'samuel@gmail.com');
      await tester.enterText(find.widgetWithText(TextField, 'Contraseña'), 'Clave123!');
      await tocar(tester, find.text('Crear usuario'));
      expect(find.textContaining('El usuario ya existe'), findsOneWidget);
      expect(find.text('Crear Nuevo Usuario'), findsOneWidget);

      await tocar(tester, find.text('Cancelar'));
      expect(find.text('Crear Nuevo Usuario'), findsNothing);
    });
  });

  group('eliminar', () {
    testWidgets('cancelar no elimina; confirmar elimina al médico', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);

      await tocar(tester, enFila('Samuel Vanegas', 'Eliminar'));
      expect(find.text('¿Eliminar médico?'), findsOneWidget);
      expect(find.textContaining('perfil de acceso', findRichText: true), findsOneWidget);
      await tocar(tester, find.text('Cancelar'));
      expect(servidor.recibio('DELETE', '/users/36'), isFalse);

      await tocar(tester, enFila('Samuel Vanegas', 'Eliminar'));
      await tocar(tester, find.text('Sí, eliminar'));
      expect(servidor.recibio('DELETE', '/users/36'), isTrue);
      expect(find.text('Médico eliminado correctamente'), findsOneWidget);
    });

    testWidgets('eliminar un paciente borra sus datos', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('Gloria Zuluaga', 'Eliminar'));
      expect(find.text('¿Eliminar paciente?'), findsOneWidget);
      expect(find.textContaining('sesiones y resultados', findRichText: true), findsOneWidget);
      await tocar(tester, find.text('Sí, eliminar'));
      expect(servidor.recibio('DELETE', '/patients/28'), isTrue);
      expect(find.text('Paciente eliminado correctamente'), findsOneWidget);
      await esperar(tester);
      expect(find.text('Gloria Zuluaga'), findsNothing);
    });

    testWidgets('eliminar un administrador; si falla lo informa', (tester) async {
      final servidor = servidorAdmin()..fallar('DELETE /users/24');
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('Admin Dos', 'Eliminar'));
      expect(find.text('¿Eliminar administrador?'), findsOneWidget);
      await tocar(tester, find.text('Sí, eliminar'));
      expect(find.textContaining('Error al eliminar'), findsOneWidget);
    });
  });

  group('editar', () {
    testWidgets('paciente: guarda los cambios', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('Gloria Zuluaga', 'Editar'));
      expect(find.text('Editar paciente'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Nombre'), 'Gloria Patricia Zuluaga');
      await tester.enterText(find.widgetWithText(TextField, 'Teléfono'), ' ');
      await tester.enterText(find.widgetWithText(TextField, 'Correo Electrónico (Opcional)'), 'gz@x.com');
      await tocar(tester, find.text('Guardar'));

      final enviado = servidor.cuerpos['PUT /patients/28'] as Map;
      expect(enviado['name'], 'Gloria Patricia Zuluaga');
      expect(enviado['phone'], isNull);
      expect(enviado['email'], 'gz@x.com');
      expect(servidor.veces('GET', '/patients/'), 2); // recarga los datos
    });

    testWidgets('paciente: nombre y edad son obligatorios; cancelar no guarda', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('Gloria Zuluaga', 'Editar'));
      await tocar(tester, find.text('Cancelar'));
      expect(servidor.recibio('PUT', '/patients/28'), isFalse);

      await tocar(tester, enFila('Gloria Zuluaga', 'Editar'));
      await tester.enterText(find.widgetWithText(TextField, 'Edad'), 'abc');
      await tocar(tester, find.text('Guardar'));
      expect(find.text('Nombre y edad son obligatorios'), findsOneWidget);
      expect(servidor.recibio('PUT', '/patients/28'), isFalse);
    });

    testWidgets('médico: cambia nombre y disponibilidad', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('Samuel Vanegas', 'Editar'));
      expect(find.text('Editar médico'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Nombre Completo'), 'Samuel V.');
      await tocar(tester, find.text('Disponible'));
      await tocar(tester, find.text('Guardar'));

      final enviado = servidor.cuerpos['PUT /users/36'] as Map;
      expect(enviado, {'username': 'samuel@gmail.com', 'full_name': 'Samuel V.', 'is_available': false});
    });

    testWidgets('administrador propio: guarda y refresca su perfil', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('samuel1@gmail.com', 'Editar').first);
      expect(find.text('Editar administrador'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Nombre Completo'), ' ');
      await tocar(tester, find.text('Activo'));
      servidor.peticiones.clear();
      await tocar(tester, find.text('Guardar'));

      expect(servidor.cuerpos['PUT /users/23'], {'username': 'samuel1@gmail.com', 'is_active': false});
      expect(servidor.recibio('GET', '/users/me'), isTrue); // es el usuario de la sesión
    });

    testWidgets('usuario: el correo es obligatorio; cancelar no guarda', (tester) async {
      final servidor = servidorAdmin();
      await abrirPanel(tester, servidor);
      await tocar(tester, enFila('Admin Dos', 'Editar'));
      await tocar(tester, find.text('Cancelar'));
      await tocar(tester, enFila('Admin Dos', 'Editar'));
      await tester.enterText(find.widgetWithText(TextField, 'Correo/Usuario'), '');
      await tocar(tester, find.text('Guardar'));
      expect(find.text('El usuario/correo es obligatorio'), findsOneWidget);
      expect(servidor.recibio('PUT', '/users/24'), isFalse);
    });
  });

  testWidgets('en pantallas angostas las tarjetas y el buscador se apilan', (tester) async {
    await abrirPanel(tester, servidorAdmin(), pantalla: const Size(500, 900));
    expect(find.text('Panel de Administrador'), findsOneWidget);
    final buscar = tester.getTopLeft(find.widgetWithText(TextField, 'Buscar médico...'));
    final chip = tester.getTopLeft(find.text('Solo disponibles'));
    expect(chip.dy, greaterThan(buscar.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cerrar sesión vuelve al inicio de sesión', (tester) async {
    final c = await abrirPanel(tester, servidorAdmin());
    await tocar(tester, find.byTooltip('Cerrar Sesión'));
    expect(rutaActual(c), '/');
  });
}
