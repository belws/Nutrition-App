import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/main.dart';
import 'package:nutrition_app/models/food.dart';
import 'package:nutrition_app/repositories/food_repository.dart';

class FakeFoodRepository implements FoodRepository {
  late final result = Completer<List<Food>>();
  int calls = 0;

  @override
  Future<List<Food>> getFoods() {
    calls++;
    return result.future;
  }
}

Food makeFood({
  String name = 'Piept de pui, crud',
  String? category = 'Carne',
  String? preparationState = 'raw',
  String basis = 'g',
  double? energy = 106,
  double? protein = 24,
  double? carbohydrates = 0,
  double? fat = 1.1,
}) => Food(
  id: name,
  name: name,
  category: category,
  preparationState: preparationState,
  nutritionBasisUnit: basis,
  energyKcal: energy,
  proteinG: protein,
  carbohydratesG: carbohydrates,
  sugarsG: null,
  fatG: fat,
  saturatedFatG: null,
  fiberG: null,
  saltG: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  late FakeFoodRepository repository;
  setUp(() => repository = FakeFoodRepository());

  testWidgets('shows loading while the request is pending', (tester) async {
    await tester.pumpWidget(MyApp(repository: repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.calls, 1);
    repository.result.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('shows a Romanian error without exposing technical details', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(repository: repository));
    repository.result.completeError(Exception('private database details'));
    await tester.pumpAndSettle();
    expect(find.text('Nu am putut încărca alimentele.'), findsOneWidget);
    expect(find.textContaining('private database details'), findsNothing);
    expect(find.text('Nu există alimente în catalog.'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an explicit empty catalog state', (tester) async {
    await tester.pumpWidget(MyApp(repository: repository));
    repository.result.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Nu există alimente în catalog.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows returned foods, metadata, nutrients and g versus ml', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(repository: repository));
    repository.result.complete([
      makeFood(),
      makeFood(name: 'Lapte 1.5%', category: 'Lactate', basis: 'ml'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Piept de pui, crud'), findsOneWidget);
    expect(find.text('Lapte 1.5%'), findsOneWidget);
    expect(find.text('Categorie: Carne'), findsOneWidget);
    expect(find.text('Categorie: Lactate'), findsOneWidget);
    expect(find.text('Preparare: raw'), findsNWidgets(2));
    expect(find.text('per 100 g'), findsOneWidget);
    expect(find.text('per 100 ml'), findsOneWidget);
    expect(find.text('Energie: 106 kcal'), findsNWidgets(2));
    expect(find.text('Proteine: 24 g'), findsNWidgets(2));
    expect(find.text('Carbohidrați: 0 g'), findsNWidgets(2));
    expect(find.text('Grăsimi: 1.1 g'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Piept de pui, crud')).dy,
      lessThan(tester.getTopLeft(find.text('Lapte 1.5%')).dy),
    );
  });

  testWidgets('distinguishes null from zero for every displayed nutrient', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(repository: repository));
    repository.result.complete([
      makeFood(energy: null, protein: null, carbohydrates: null, fat: null),
      makeFood(name: 'Zero', energy: 0, protein: 0, carbohydrates: 0, fat: 0),
    ]);
    await tester.pumpAndSettle();
    for (final label in ['Energie', 'Proteine', 'Carbohidrați', 'Grăsimi']) {
      expect(find.text('$label: —'), findsOneWidget);
      final unit = label == 'Energie' ? 'kcal' : 'g';
      expect(find.text('$label: 0 $unit'), findsOneWidget);
    }
  });

  testWidgets('omits null optional metadata', (tester) async {
    await tester.pumpWidget(MyApp(repository: repository));
    repository.result.complete([
      makeFood(category: null, preparationState: null),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Piept de pui, crud'), findsOneWidget);
    expect(find.textContaining('Categorie:'), findsNothing);
    expect(find.textContaining('Preparare:'), findsNothing);
    expect(find.textContaining('null'), findsNothing);
  });

  testWidgets('parent rebuilds do not fetch again', (tester) async {
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpWidget(MyApp(repository: repository));
    expect(repository.calls, 1);
    repository.result.complete([makeFood()]);
    await tester.pumpAndSettle();
    await tester.pumpWidget(MyApp(repository: repository));
    await tester.pumpAndSettle();
    expect(repository.calls, 1);
    expect(find.text('Piept de pui, crud'), findsOneWidget);
  });
}
