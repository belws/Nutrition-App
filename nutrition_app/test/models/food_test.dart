import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/food.dart';

void main() {
  group('Food.fromJson', () {
    late Map<String, dynamic> json;

    setUp(() {
      json = {
        'id': '11111111-1111-4111-8111-111111111111',
        'name': 'Aliment de test',
        'category': 'Categorie de test',
        'preparation_state': 'raw',
        'nutrition_basis_unit': 'g',
        'energy_kcal': 106.5,
        'protein_g': 24.1,
        'carbohydrates_g': 3.2,
        'sugars_g': 1.3,
        'fat_g': 1.4,
        'saturated_fat_g': 0.5,
        'fiber_g': 0.6,
        'salt_g': 0.0075,
        'created_at': '2026-10-04T17:00:00+03:00',
        'updated_at': '2026-10-04T14:30:00Z',
      };
    });

    List<double?> nutritionValues(Food food) => [
      food.energyKcal,
      food.proteinG,
      food.carbohydratesG,
      food.sugarsG,
      food.fatG,
      food.saturatedFatG,
      food.fiberG,
      food.saltG,
    ];

    const nutritionKeys = [
      'energy_kcal',
      'protein_g',
      'carbohydrates_g',
      'sugars_g',
      'fat_g',
      'saturated_fat_g',
      'fiber_g',
      'salt_g',
    ];

    test('maps snake_case fields and normalizes timestamps to UTC', () {
      final food = Food.fromJson(json);

      expect(food.id, json['id']);
      expect(food.name, 'Aliment de test');
      expect(food.category, 'Categorie de test');
      expect(food.preparationState, 'raw');
      expect(food.nutritionBasisUnit, 'g');
      expect(nutritionValues(food), [
        106.5,
        24.1,
        3.2,
        1.3,
        1.4,
        0.5,
        0.6,
        0.0075,
      ]);
      expect(food.createdAt, DateTime.utc(2026, 10, 4, 14));
      expect(food.updatedAt, DateTime.utc(2026, 10, 4, 14, 30));
      expect(food.createdAt.isUtc, isTrue);
      expect(food.updatedAt.isUtc, isTrue);
    });

    test('preserves nullable fields and the ml basis', () {
      json['category'] = null;
      json['preparation_state'] = null;
      json['nutrition_basis_unit'] = 'ml';
      for (final key in nutritionKeys) {
        json[key] = null;
      }

      final food = Food.fromJson(json);

      expect(food.category, isNull);
      expect(food.preparationState, isNull);
      expect(food.nutritionBasisUnit, 'ml');
      expect(nutritionValues(food), everyElement(isNull));
    });

    test('converts integer nutrition values, including zero, to doubles', () {
      for (var i = 0; i < nutritionKeys.length; i++) {
        json[nutritionKeys[i]] = i;
      }

      final values = nutritionValues(Food.fromJson(json));

      expect(values, [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]);
      expect(values, everyElement(isA<double>()));
    });

    test('does not substitute defaults for missing nullable fields', () {
      for (final key in ['category', 'preparation_state', ...nutritionKeys]) {
        json.remove(key);
      }

      final food = Food.fromJson(json);

      expect(food.category, isNull);
      expect(food.preparationState, isNull);
      expect(nutritionValues(food), everyElement(isNull));
    });

    test('rejects missing required fields instead of inventing defaults', () {
      for (final key in [
        'id',
        'name',
        'nutrition_basis_unit',
        'created_at',
        'updated_at',
      ]) {
        final incomplete = Map<String, dynamic>.from(json)..remove(key);
        expect(() => Food.fromJson(incomplete), throwsA(isA<TypeError>()));
      }
    });

    test('propagates malformed timestamps', () {
      json['updated_at'] = 'not-a-timestamp';
      expect(() => Food.fromJson(json), throwsFormatException);
    });
  });
}
