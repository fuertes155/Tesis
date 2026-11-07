import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(768, 1024),
    const Size(1440, 1000),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('login sin desbordamientos ${size.width} px texto $scale', (
        tester,
      ) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          Builder(
            builder: (context) => ProviderScope(
              child: MaterialApp(
                theme: AppTheme.buildTheme(context, Brightness.light),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const LoginScreen(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.widgetWithText(TextField, 'Usuario'), findsOneWidget);
        await tester.ensureVisible(find.text('INICIAR SESIÓN'));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('login: contraste, etiquetas y objetivos táctiles', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      Builder(
        builder: (context) => ProviderScope(
          child: MaterialApp(
            theme: AppTheme.buildTheme(context, Brightness.light),
            home: const LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    try {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });
}
