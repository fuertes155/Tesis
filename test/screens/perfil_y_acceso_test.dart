// Perfil, verificación en dos pasos y restablecimiento de contraseña.
import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/api_providers.dart';
import 'package:flutter_application_1/providers/theme_provider.dart';
import 'package:flutter_application_1/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_de_prueba.dart';
import '../helpers/servidor_simulado.dart';

final _casillas = find.byType(TextField);

Future<void> escribirCodigo(WidgetTester tester, String codigo) async {
  for (var i = 0; i < codigo.length; i++) {
    await tester.enterText(_casillas.at(i), codigo[i]);
    await tester.pump();
  }
  await esperar(tester);
}

void main() {
  group('perfil', () {
    Future<ProviderContainer> abrir(WidgetTester tester) async {
      final c = await montarApp(tester, ServidorSimulado(), rolConSesion: 'doctor');
      await irA(tester, c, '/home');
      c.read(routerProvider).push('/profile');
      await esperar(tester);
      return c;
    }

    testWidgets('muestra el usuario de la sesión y su rol', (tester) async {
      await abrir(tester);
      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.text('SAMUEL'), findsOneWidget);
      expect(find.text('S'), findsOneWidget); // inicial del avatar
      expect(find.text('samuel@gmail.com'), findsOneWidget);
      expect(find.text('DOCTOR'), findsOneWidget);
    });

    testWidgets('el interruptor cambia entre modo claro y oscuro', (tester) async {
      final c = await abrir(tester);
      expect(find.text('Claro'), findsOneWidget);
      await tocar(tester, find.byType(Switch));
      expect(c.read(themeProvider), ThemeMode.dark);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
      await tocar(tester, find.byType(Switch));
      expect(c.read(themeProvider), ThemeMode.light);
    });

    testWidgets('cambiar contraseña aún no está disponible', (tester) async {
      await abrir(tester);
      await tocar(tester, find.text('Cambiar Contraseña'));
      expect(find.text('Función disponible en la próxima versión'), findsOneWidget);
    });

    testWidgets('Cerrar Sesión vuelve al inicio de sesión', (tester) async {
      final c = await abrir(tester);
      await tocar(tester, find.text('Cerrar Sesión'));
      expect(rutaActual(c), '/');
    });
  });

  group('verificación en dos pasos', () {
    Future<ProviderContainer> abrir(WidgetTester tester, ServidorSimulado servidor, {String rol = 'doctor'}) async {
      final c = await montarApp(tester, servidor, rolConSesion: rol);
      await irA(tester, c, '/mfa');
      return c;
    }

    testWidgets('con el código correcto entra según el rol', (tester) async {
      for (final (rol, destino) in [('doctor', '/home'), ('gestor', '/users_admin'), ('user', '/patient_welcome')]) {
        final servidor = ServidorSimulado(pacientes: [pacienteEjemplo()]);
        final c = await abrir(tester, servidor, rol: rol);
        expect(find.text('Verificación de Dos Pasos'), findsOneWidget);
        await escribirCodigo(tester, ServidorSimulado.codigo2fa);
        expect(rutaActual(c), destino, reason: rol);
        expect((servidor.cuerpos['POST /users/verify-2fa'] as Map)['code'], ServidorSimulado.codigo2fa);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('un código incorrecto muestra el error', (tester) async {
      final c = await abrir(tester, ServidorSimulado());
      await escribirCodigo(tester, '000000');
      expect(find.text('Código de verificación incorrecto'), findsOneWidget);
      expect(rutaActual(c), '/mfa');
    });

    testWidgets('si el servidor no confirma, también es un error', (tester) async {
      final servidor = ServidorSimulado()
        ..fallar('POST /users/verify-2fa', estado: 200, cuerpo: {'status': 'pending'});
      await abrir(tester, servidor);
      await escribirCodigo(tester, '123456');
      expect(find.text('Código de verificación incorrecto'), findsOneWidget);
    });

    testWidgets('VERIFICAR con el código incompleto no consulta al servidor', (tester) async {
      final servidor = ServidorSimulado();
      await abrir(tester, servidor);
      await escribirCodigo(tester, '123');
      await tocar(tester, find.text('VERIFICAR'));
      expect(servidor.recibio('POST', '/users/verify-2fa'), isFalse);
    });

    testWidgets('borrar un dígito devuelve el foco a la casilla anterior', (tester) async {
      await abrir(tester, ServidorSimulado());
      await escribirCodigo(tester, '12');
      await tester.enterText(_casillas.at(1), '');
      await tester.pump();
      final foco = tester.widget<TextField>(_casillas.at(0)).focusNode!;
      expect(foco.hasFocus, isTrue);
    });

    testWidgets('sin usuario en la sesión no se puede verificar', (tester) async {
      final c = await abrir(tester, ServidorSimulado());
      final api = c.read(apiServiceProvider).requireValue;
      await api.logout();
      await escribirCodigo(tester, '123456');
      expect(find.text('No se encontró el nombre de usuario'), findsOneWidget);
    });

    testWidgets('Volver al inicio de sesión', (tester) async {
      final c = await abrir(tester, ServidorSimulado());
      await tocar(tester, find.text('Volver al inicio de sesión'));
      expect(rutaActual(c), '/');
    });
  });

  group('restablecer contraseña', () {
    Future<ProviderContainer> abrir(WidgetTester tester) async {
      final c = await montarApp(tester, ServidorSimulado());
      await irA(tester, c, '/reset_password');
      return c;
    }

    Future<void> llenar(WidgetTester tester, String usuario, String clave, String confirmar) async {
      await tester.enterText(find.widgetWithText(TextFormField, 'Usuario'), usuario);
      await tester.enterText(find.widgetWithText(TextFormField, 'Nueva contraseña'), clave);
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirmar contraseña'), confirmar);
      await tester.pump();
    }

    testWidgets('indica la fortaleza de la contraseña mientras se escribe', (tester) async {
      await abrir(tester);
      final clave = find.widgetWithText(TextFormField, 'Nueva contraseña');
      for (final (texto, etiqueta) in [
        ('abc', 'Débil'),
        ('abcdefgh1', 'Medio'),
        ('Abcdefgh1', 'Fuerte'),
        ('Abcdefgh1!', 'Muy Fuerte'),
      ]) {
        await tester.enterText(clave, texto);
        await tester.pump();
        expect(find.text(etiqueta), findsOneWidget, reason: texto);
      }
    });

    testWidgets('valida campos vacíos, coincidencia y fortaleza', (tester) async {
      await abrir(tester);
      await tocar(tester, find.text('RESTABLECER'));
      expect(find.text('Exception: Ingresa usuario y nueva contraseña'), findsOneWidget);

      await llenar(tester, 'samuel@gmail.com', 'Abcdefgh1!', 'Otra1234!');
      await tocar(tester, find.text('RESTABLECER'));
      expect(find.text('Exception: Las contraseñas no coinciden'), findsOneWidget);

      await llenar(tester, 'samuel@gmail.com', 'abcdefgh', 'abcdefgh');
      await tocar(tester, find.text('RESTABLECER'));
      expect(find.textContaining('mínimo 8 caracteres'), findsOneWidget);
    });

    testWidgets('con datos válidos (enviados con Intro) confirma el cambio', (tester) async {
      await abrir(tester);
      await llenar(tester, 'samuel@gmail.com', 'Abcdefgh1!', 'Abcdefgh1!');
      await tester.showKeyboard(find.widgetWithText(TextFormField, 'Nueva contraseña'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await esperar(tester);
      expect(find.text('Contraseña actualizada'), findsOneWidget);
    });

    testWidgets('Volver a iniciar sesión', (tester) async {
      final c = await abrir(tester);
      await tocar(tester, find.text('Volver a iniciar sesión'));
      expect(rutaActual(c), '/');
    });
  });
}
