import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/user_profile.dart';

void main() {
  late Map<String, dynamic> row;

  setUp(() {
    row = {
      'user_id': '11111111-1111-4111-8111-111111111111',
      'sex': 'female',
      'date_of_birth': '1992-02-29',
      'height_cm': 170,
      'weight_kg': 65.5,
      'activity_level': 'moderately_active',
      'goal': 'maintain',
      'created_at': '2026-10-07T12:00:00+03:00',
      'updated_at': '2026-10-07T10:00:00Z',
    };
  });

  test('fromJson maps fields, numeric values and timestamps', () {
    final profile = UserProfile.fromJson(row);
    expect(profile.userId, row['user_id']);
    expect(profile.sex, 'female');
    expect(profile.dateOfBirth, DateTime(1992, 2, 29));
    expect(profile.heightCm, 170.0);
    expect(profile.heightCm, isA<double>());
    expect(profile.weightKg, 65.5);
    expect(profile.activityLevel, 'moderately_active');
    expect(profile.goal, 'maintain');
    expect(profile.createdAt, DateTime.utc(2026, 10, 7, 9));
    expect(profile.updatedAt, DateTime.utc(2026, 10, 7, 10));
  });

  test('converts integer weight and decimal height to doubles', () {
    row['height_cm'] = 170.5;
    row['weight_kg'] = 65;
    final profile = UserProfile.fromJson(row);
    expect(profile.heightCm, 170.5);
    expect(profile.weightKg, 65.0);
    expect(profile.weightKg, isA<double>());
  });

  test('toJson uses snake_case and excludes database-managed timestamps', () {
    expect(UserProfile.fromJson(row).toJson(), {
      'user_id': row['user_id'],
      'sex': 'female',
      'date_of_birth': '1992-02-29',
      'height_cm': 170.0,
      'weight_kg': 65.5,
      'activity_level': 'moderately_active',
      'goal': 'maintain',
    });
  });

  test('unsaved profile serializes a padded date without a time or offset', () {
    final profile = UserProfile(
      userId: row['user_id'] as String,
      sex: 'male',
      dateOfBirth: DateTime.utc(2000, 1, 2),
      heightCm: 180,
      weightKg: 80,
      activityLevel: 'sedentary',
      goal: 'lose',
    );
    expect(profile.createdAt, isNull);
    expect(profile.updatedAt, isNull);
    expect(profile.toJson()['date_of_birth'], '2000-01-02');
  });

  test('preserves every database enum string exactly', () {
    final values = {
      'sex': ['male', 'female'],
      'activity_level': [
        'sedentary',
        'lightly_active',
        'moderately_active',
        'very_active',
        'extra_active',
      ],
      'goal': ['lose', 'maintain', 'gain'],
    };
    for (final entry in values.entries) {
      for (final value in entry.value) {
        row[entry.key] = value;
        expect(UserProfile.fromJson(row).toJson()[entry.key], value);
      }
    }
  });
}
