import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('NeuroApp'), findsWidgets);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
