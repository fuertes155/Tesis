// Componentes compartidos y extensiones del tema, probados de forma aislada.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/games/common/game_intro.dart';
import 'package:flutter_application_1/providers/api_providers.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:flutter_application_1/widgets/dashboard_card.dart';
import 'package:flutter_application_1/widgets/empty_state_view.dart';
import 'package:flutter_application_1/widgets/home_dashboard_grid.dart';
import 'package:flutter_application_1/widgets/home_hero_banner.dart';
import 'package:flutter_application_1/widgets/mini_bars_sparkline.dart';
import 'package:flutter_application_1/widgets/premium_button.dart';
import 'package:flutter_application_1/widgets/session_stepper.dart';
import 'package:flutter_application_1/widgets/stat_card.dart';
import 'package:flutter_application_1/widgets/status_badge.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta un widget suelto con el tema real de la app.
Future<void> montar(WidgetTester tester, Widget hijo, {List<Override> overrides = const []}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  rootBundle.clear();
  await initializeDateFormatting('es');
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: Builder(
      builder: (context) => MaterialApp(
        theme: AppTheme.buildTheme(context, Brightness.light),
        home: Scaffold(body: Center(child: hijo)),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('PremiumButton', () {
    testWidgets('deshabilitado no responde y cargando muestra el indicador', (tester) async {
      await montar(tester, const Column(mainAxisSize: MainAxisSize.min, children: [
        PremiumButton(label: 'Guardar', onPressed: null),
        PremiumButton(label: 'Enviar', onPressed: null, isLoading: true),
      ]));
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Enviar'), findsNothing);
    });

    testWidgets('al arrastrar fuera el toque se cancela', (tester) async {
      var toques = 0;
      await montar(tester, PremiumButton(label: 'Guardar', icon: Icons.save, onPressed: () => toques++));
      final gesto = await tester.startGesture(tester.getCenter(find.text('Guardar')));
      await tester.pump(const Duration(milliseconds: 50));
      await gesto.moveBy(const Offset(0, 300));
      await gesto.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(toques, 0);

      await tester.tap(find.text('Guardar'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(toques, 1);
    });
  });

  group('StatusBadge', () {
    testWidgets('el punto late solo cuando se pide y se puede apagar', (tester) async {
      Future<void> conPulso(bool pulso) => montar(
            tester,
            StatusBadge(label: 'Disponible', color: Colors.green, pulse: pulso),
          );
      await conPulso(true);
      expect(find.byType(AnimatedBuilder), findsWidgets);
      await conPulso(false);
      await conPulso(true);
      expect(find.text('Disponible'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('tarjetas', () {
    testWidgets('StatCard con tendencia a la baja y mini gráfica', (tester) async {
      await montar(
        tester,
        const SizedBox(
          width: 260,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            StatCard(
              title: 'Pendientes', value: '4', icon: Icons.schedule, color: Colors.orange,
              caption: 'esta semana', trendText: '-20%', trendUp: false, sparklinePoints: [1, 3, 0, 2],
            ),
            StatCard(title: 'Hoy', value: '0', icon: Icons.today, color: Colors.blue, sparklinePoints: [0, 0]),
          ]),
        ),
      );
      expect(find.text('-20%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down_rounded), findsOneWidget);
      expect(find.byType(MiniBarsSparkline), findsNWidgets(2));
    });

    testWidgets('MiniBarsSparkline sin datos no dibuja barras', (tester) async {
      await montar(tester, const SizedBox(width: 100, height: 28, child: MiniBarsSparkline(points: [])));
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('DashboardCard principal se resalta al pasar el mouse', (tester) async {
      var abierta = false;
      await montar(
        tester,
        SizedBox(
          width: 320,
          child: DashboardCard(
            icon: Icons.play_arrow, title: 'Nueva sesión', subtitle: 'Iniciar', color: Colors.blue,
            isPrimary: true, onTap: () => abierta = true,
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Nueva sesión')));
      await tester.pump(const Duration(milliseconds: 300));
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Nueva sesión'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(abierta, isTrue);
    });

    testWidgets('EmptyStateView con ícono SVG', (tester) async {
      await montar(
        tester,
        const EmptyStateView(title: 'Vacío', description: 'Nada aún', iconPath: 'assets/svg/hospital_logo.svg'),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(find.text('Vacío'), findsOneWidget);
    });
  });

  group('inicio', () {
    testWidgets('el banner del paciente ofrece ver sus resultados', (tester) async {
      var vistos = false;
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await montar(
        tester,
        SingleChildScrollView(
          child: HomeHeroBanner(
            loading: false, sessionsToday: 0, sessionsPending: 0, role: 'user', fallbackName: 'Ana',
            onNewSession: () {}, onPatients: () {}, onResults: () => vistos = true,
          ),
        ),
      );
      expect(find.text('Nueva sesión'), findsNothing);
      await tester.tap(find.text('Ver mis resultados'));
      expect(vistos, isTrue);
    });

    for (final (rol, esperado) in [
      ('user', 'Historial y estadísticas'),
      (null, 'No hay accesos rápidos para este usuario (sesión no iniciada).'),
      ('invitado', 'No hay accesos rápidos para este usuario (rol: invitado).'),
    ]) {
      testWidgets('accesos rápidos para el rol $rol', (tester) async {
        SharedPreferences.setMockInitialValues({if (rol != null) 'api_role': rol});
        await montar(
          tester,
          const SingleChildScrollView(child: HomeDashboardGrid()),
          overrides: [
            apiServiceProvider.overrideWith((ref) async {
              final api = ApiService(Dio());
              await api.init();
              return api;
            }),
          ],
        );
        expect(find.textContaining(esperado), findsWidgets);
      });
    }

    testWidgets('el indicador de pasos marca los pasos hechos', (tester) async {
      await montar(tester, const SessionStepper(current: 2));
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('la introducción de un juego puede llevar un pie', (tester) async {
      await montar(
        tester,
        GameIntro(
          title: 'Prueba', subtitle: 'Sub', icon: Icons.abc, steps: const ['Paso'], actionLabel: 'Ir',
          onStart: () {}, footer: const Text('Pie de página'),
        ),
      );
      expect(find.text('Pie de página'), findsOneWidget);
    });
  });

  group('extensiones del tema', () {
    test('copyWith conserva o reemplaza cada valor', () {
      const espacios = AppSpacing();
      expect(espacios.copyWith(), isA<AppSpacing>());
      expect(espacios.copyWith(xs: 1, sm: 2, md: 3, lg: 4, xl: 5, x2l: 6).x2l, 6);
      expect(espacios.copyWith().md, espacios.md);

      const radios = AppRadii();
      expect(radios.copyWith(sm: 1, md: 2, lg: 3, xl: 4).xl, 4);
      expect(radios.copyWith().lg, radios.lg);

      final colores = AppSemanticColors.light();
      expect(colores.copyWith(success: Colors.black, warning: Colors.black, info: Colors.black, danger: Colors.black)
          .danger, Colors.black);
      expect(colores.copyWith().info, colores.info);

      final vidrio = AppGlass.forBrightness(false, Colors.blue, Colors.grey);
      final otro = AppGlass.forBrightness(true, Colors.red, Colors.black);
      expect(vidrio.copyWith(blurSigma: 3).blurSigma, 3);
      expect(vidrio.copyWith(
        cardGradient: otro.cardGradient, overlayColor: Colors.white, borderColor: Colors.white,
        headerGradient: otro.headerGradient, accentGradient: otro.accentGradient,
      ).borderColor, Colors.white);
      expect(vidrio.lerp(otro, 0.5), isA<AppGlass>());

      const sombras = AppPremiumShadows(premiumShadow: [BoxShadow(blurRadius: 4)]);
      expect(sombras.copyWith().premiumShadow, sombras.premiumShadow);
      expect(sombras.copyWith(premiumShadow: const []).premiumShadow, isEmpty);
      expect(sombras.lerp(const AppPremiumShadows(premiumShadow: [BoxShadow(blurRadius: 8)]), 0.5), isA<AppPremiumShadows>());
    });

    testWidgets('sin extensiones en el tema se usan valores por defecto según el brillo', (tester) async {
      for (final brillo in Brightness.values) {
        late BuildContext ctx;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(brightness: brillo),
          home: Builder(builder: (c) {
            ctx = c;
            return const SizedBox();
          }),
        ));
        await tester.pump(const Duration(milliseconds: 400)); // el cambio de tema es animado
        expect(ctx.sem.success, brillo == Brightness.dark ? AppSemanticColors.dark().success : AppSemanticColors.light().success);
        expect(ctx.glass, isA<AppGlass>());
      }
    });

    testWidgets('tamaño de pantalla: teléfono, tableta y escritorio', (tester) async {
      for (final (ancho, movil, tableta, escritorio) in [
        (400.0, true, false, false),
        (800.0, false, true, false),
        (1200.0, false, false, true),
      ]) {
        tester.view.physicalSize = Size(ancho, 800);
        tester.view.devicePixelRatio = 1;
        late BuildContext ctx;
        await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        })));
        expect((ctx.isMobile, ctx.isTablet, ctx.isDesktop), (movil, tableta, escritorio), reason: '$ancho px');
      }
      tester.view.reset();
    });
  });
}
