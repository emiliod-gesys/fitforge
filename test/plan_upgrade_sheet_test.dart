import 'package:fitforge/core/subscription/plan_upgrade.dart';
import 'package:fitforge/l10n/app_localizations.dart';
import 'package:fitforge/models/profile.dart';
import 'package:fitforge/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfile _profile({
  SubscriptionTier tier = SubscriptionTier.free,
  SubscriptionSource source = SubscriptionSource.none,
}) {
  return UserProfile(
    id: 'u1',
    createdAt: DateTime.utc(2026, 1, 1),
    subscriptionTier: tier,
    subscriptionSource: source,
  );
}

Future<void> _openSheet(
  WidgetTester tester, {
  required UserProfile profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith((ref) async => profile),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('Sigue aquí'),
                TextButton(
                  onPressed: () => PlanUpgrade.openPlan(context),
                  child: const Text('Abrir'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('un plan bloqueado abre los beneficios sin salir de la pantalla',
      (tester) async {
    await _openSheet(tester, profile: _profile());

    expect(find.text('Sigue aquí'), findsOneWidget);
    expect(find.text('10 rutinas guardadas'), findsOneWidget);
    expect(find.text('IA proactiva al entrenar'), findsOneWidget);
    expect(
      find.text('Foto de comida con IA + código de barras'),
      findsOneWidget,
    );
    expect(find.text(r'$7.99'), findsOneWidget);
    expect(find.text(r'$11.99'), findsOneWidget);
    expect(find.text('Pasar a Gymrat Pro'), findsOneWidget);

    await tester.ensureVisible(find.text('Gymrat'));
    await tester.tap(find.text('Gymrat'));
    await tester.pumpAndSettle();

    expect(find.text('Pasar a Gymrat'), findsOneWidget);
    expect(find.text('Sigue aquí'), findsOneWidget);
  });

  testWidgets('una cortesía muestra los planes sin botón de compra',
      (tester) async {
    await _openSheet(
      tester,
      profile: _profile(
        tier: SubscriptionTier.gymratPro,
        source: SubscriptionSource.courtesy,
      ),
    );

    expect(find.text('Sigue aquí'), findsOneWidget);
    expect(find.text('Tu plan'), findsOneWidget);
    expect(find.text('50 rutinas guardadas'), findsOneWidget);
    expect(find.text('Pasar a Gymrat Pro'), findsNothing);
    expect(find.text('Pasar a Gymrat'), findsNothing);
  });
}
