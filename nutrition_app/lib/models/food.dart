/// A generic food with nutrition values per 100 g or 100 ml.
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.preparationState,
    required this.nutritionBasisUnit,
    required this.energyKcal,
    required this.proteinG,
    required this.carbohydratesG,
    required this.sugarsG,
    required this.fatG,
    required this.saturatedFatG,
    required this.fiberG,
    required this.saltG,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? category;
  final String? preparationState;
  final String nutritionBasisUnit;
  final double? energyKcal;
  final double? proteinG;
  final double? carbohydratesG;
  final double? sugarsG;
  final double? fatG;
  final double? saturatedFatG;
  final double? fiberG;
  final double? saltG;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      preparationState: json['preparation_state'] as String?,
      nutritionBasisUnit: json['nutrition_basis_unit'] as String,
      energyKcal: (json['energy_kcal'] as num?)?.toDouble(),
      proteinG: (json['protein_g'] as num?)?.toDouble(),
      carbohydratesG: (json['carbohydrates_g'] as num?)?.toDouble(),
      sugarsG: (json['sugars_g'] as num?)?.toDouble(),
      fatG: (json['fat_g'] as num?)?.toDouble(),
      saturatedFatG: (json['saturated_fat_g'] as num?)?.toDouble(),
      fiberG: (json['fiber_g'] as num?)?.toDouble(),
      saltG: (json['salt_g'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }
}
