import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/food.dart';
import 'package:nutrition_app/repositories/food_repository.dart';
import 'package:nutrition_app/screens/food_catalog_screen.dart';

class FakeFoodRepository extends FoodRepository {
  FakeFoodRepository(this.result);

  final Future<List<Food>> result;
  int calls = 0;

  @override
  Future<List<Food>> getFoods() {
    calls++;
    return result;
  }
}

Food createFood({Map<String, dynamic> overrides = const {}}) {
  return Food.fromJson({
    'id': '11111111-1111-4111-8111-111111111111',
    'name': 'Aliment de test',
    'category': 'Categorie de test',
    'preparation_state': 'raw',
    'nutrition_basis_unit': 'g',
    'energy_kcal': 106.5,
    'protein_g': 24.1,
    'carbohydrates_g': 3.2,
    'sugars_g': null,
    'fat_g': 1.4,
    'saturated_fat_g': null,
    'fiber_g': null,
    'salt_g': null,
    'created_at': '2026-10-04T17:00:00Z',
    'updated_at': '2026-10-04T17:00:00Z',
    ...overrides,
  });
}

void main() {
  testWidgets('shows loading state while foods are loading', (tester) async {
    final repository = FakeFoodRepository(Completer<List<Food>>().future);
    await tester.pumpWidget(
      MaterialApp(
        home: FoodCatalogScreen(repository: repository, onSignOut: () async {}),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no foods exist', (tester) async {
    final repository = FakeFoodRepository(Future.value([]));

    await tester.pumpWidget(
      MaterialApp(
        home: FoodCatalogScreen(repository: repository, onSignOut: () async {}),
      ),
    );

    await tester.pump();

    expect(find.text('Nu există alimente în catalog.'), findsOneWidget);
  });

  testWidgets('shows error state when loading fails', (tester) async {
    final repository = FakeFoodRepository(
      Future<List<Food>>(() => throw Exception('test error')),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FoodCatalogScreen(repository: repository, onSignOut: () async {}),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Nu am putut încărca alimentele.'), findsOneWidget);
    expect(find.textContaining('test error'), findsNothing);
  });

  testWidgets('shows loaded food data and preserves unknown values', (
    tester,
  ) async {
    final repository = FakeFoodRepository(Future.value([createFood()]));

    await tester.pumpWidget(
      MaterialApp(
        home: FoodCatalogScreen(repository: repository, onSignOut: () async {}),
      ),
    );

    await tester.pump();

    expect(find.text('Aliment de test'), findsOneWidget);
    expect(find.text('Categorie: Categorie de test'), findsOneWidget);
    expect(find.text('Preparare: raw'), findsOneWidget);
    expect(find.text('per 100 g'), findsOneWidget);
    expect(find.text('Energie: 106.5 kcal'), findsOneWidget);
    expect(find.text('Proteine: 24.1 g'), findsOneWidget);
    expect(find.text('Carbohidrați: 3.2 g'), findsOneWidget);
    expect(find.text('Grăsimi: 1.4 g'), findsOneWidget);
  });

  testWidgets('distinguishes null nutrients from zero with correct units', (
    tester,
  ) async {
    final repository = FakeFoodRepository(
      Future.value([
        createFood(
          overrides: {
            'energy_kcal': null,
            'protein_g': null,
            'carbohydrates_g': null,
            'fat_g': null,
          },
        ),
        createFood(
          overrides: {
            'id': '22222222-2222-4222-8222-222222222222',
            'name': 'Valori zero',
            'energy_kcal': 0,
            'protein_g': 0,
            'carbohydrates_g': 0,
            'fat_g': 0,
          },
        ),
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FoodCatalogScreen(repository: repository, onSignOut: () async {}),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Energie', 'Proteine', 'Carbohidrați', 'Grăsimi']) {
      expect(find.text('$label: —'), findsOneWidget);
      final unit = label == 'Energie' ? 'kcal' : 'g';
      expect(find.text('$label: 0 $unit'), findsOneWidget);
    }
  });

  testWidgets('shows both g and ml nutrition bases', (tester) async {
    final repository = FakeFoodRepository(
      Future.value([
        createFood(),
        createFood(
          overrides: {
            'id': '22222222-2222-4222-8222-222222222222',
            'name': 'Lapte',
            'nutrition_basis_unit': 'ml',
          },
        ),
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FoodCatalogScreen(repository: repository, onSignOut: () async {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('per 100 g'), findsOneWidget);
    expect(find.text('per 100 ml'), findsOneWidget);
  });

  testWidgets('omits null optional metadata', (tester) async {
    final repository = FakeFoodRepository(
      Future.value([
        createFood(overrides: {'category': null, 'preparation_state': null}),
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FoodCatalogScreen(repository: repository, onSignOut: () async {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aliment de test'), findsOneWidget);
    expect(find.textContaining('Categorie:'), findsNothing);
    expect(find.textContaining('Preparare:'), findsNothing);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('parent rebuilds do not fetch foods again', (tester) async {
    final completer = Completer<List<Food>>();
    final repository = FakeFoodRepository(completer.future);
    Widget buildApp() => MaterialApp(
      home: FoodCatalogScreen(repository: repository, onSignOut: () async {}),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpWidget(buildApp());
    expect(repository.calls, 1);

    completer.complete([createFood()]);
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(find.text('Aliment de test'), findsOneWidget);
  });

  testWidgets('sign-out button invokes injected callback', (tester) async {
    var signOutCalled = false;
    final repository = FakeFoodRepository(Future.value([]));

    await tester.pumpWidget(
      MaterialApp(
        home: FoodCatalogScreen(
          repository: repository,
          onSignOut: () async {
            signOutCalled = true;
          },
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(signOutCalled, isTrue);
  });

  testWidgets('shows friendly message when sign out fails', (tester) async {
    final repository = FakeFoodRepository(Future.value([]));

    await tester.pumpWidget(
      MaterialApp(
        home: FoodCatalogScreen(
          repository: repository,
          onSignOut: () async {
            throw Exception('raw sign-out error');
          },
        ),
      ),
    );

    await tester.pump();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();

    expect(
      find.text('Nu am putut face deconectarea. Încearcă din nou.'),
      findsOneWidget,
    );
    expect(find.textContaining('raw sign-out error'), findsNothing);
  });
}
