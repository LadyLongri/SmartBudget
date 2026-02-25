import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbudget/screens/auth_screen.dart';
import 'package:smartbudget/screens/frontend_home_screen.dart';

void main() {
  group('QA user flow', () {
    testWidgets(
      'login UI validates input before auth call',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

        await tester.tap(find.text('Se connecter'));
        await tester.pump();

        expect(find.text('Email requis'), findsOneWidget);
        expect(find.text('Mot de passe requis'), findsOneWidget);

        await tester.tap(find.text('Inscription').first);
        await tester.pump();

        final Finder fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'qa@smartbudget.app');
        await tester.enterText(fields.at(1), '123');
        await tester.tap(find.text("S'inscrire"));
        await tester.pump();

        expect(find.text('Minimum 6 caracteres'), findsOneWidget);
      },
    );

    testWidgets(
      'CRUD transaction updates stats dashboard view',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: FrontendHomeScreen()));

        expect(find.text('No transaction yet'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Title'),
          'Taxi local',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Amount'),
          '25',
        );
        await tester.tap(find.textContaining('Save day'));
        await tester.pumpAndSettle();

        expect(find.text('Taxi local'), findsOneWidget);
        expect(find.textContaining('25.00'), findsWidgets);

        await tester.tap(find.text('Statistic').last);
        await tester.pumpAndSettle();

        expect(find.textContaining('Top category:'), findsOneWidget);

        await tester.tap(find.text('Wallet').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reset data'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Transaction').last);
        await tester.pumpAndSettle();

        expect(find.text('No transaction yet'), findsOneWidget);
      },
    );
  });
}
