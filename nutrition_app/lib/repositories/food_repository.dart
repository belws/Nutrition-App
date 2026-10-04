import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food.dart';

class FoodRepository {
  /// Reads foods ordered by name, with id as a tie-breaker.
  ///
  /// Uses one request and is limited by Supabase's configured maximum response
  /// size. This method does not paginate and may not return the entire catalog.
  /// Query and parsing errors propagate to the caller.
  Future<List<Food>> getFoods() async {
    final rows = await Supabase.instance.client
        .schema('public')
        .from('foods')
        .select(
          'id, name, category, preparation_state, nutrition_basis_unit, '
          'energy_kcal, protein_g, carbohydrates_g, sugars_g, fat_g, '
          'saturated_fat_g, fiber_g, salt_g, created_at, updated_at',
        )
        .order('name', ascending: true)
        .order('id', ascending: true);

    return rows.map(Food.fromJson).toList();
  }
}
