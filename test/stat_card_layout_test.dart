import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/widgets/stat_card.dart';

void main() {
  testWidgets('StatCard lays out inside scroll/wrap without flex assertion',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Wrap(
              children: const [
                SizedBox(
                  width: 320,
                  child: StatCard(
                    title: 'Pacientes',
                    value: '0',
                    icon: Icons.people_outline,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pacientes'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}

