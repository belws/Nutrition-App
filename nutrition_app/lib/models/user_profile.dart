class UserProfile {
  const UserProfile({
    required this.userId,
    required this.sex,
    required this.dateOfBirth,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String sex;

  /// Calendar date only; serialization preserves year/month/day without a
  /// timezone conversion.
  final DateTime dateOfBirth;
  final double heightCm;
  final double weightKg;
  final String activityLevel;
  final String goal;

  /// Database-managed timestamps, absent on a profile not yet saved.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      sex: json['sex'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      heightCm: (json['height_cm'] as num).toDouble(),
      weightKg: (json['weight_kg'] as num).toDouble(),
      activityLevel: json['activity_level'] as String,
      goal: json['goal'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  /// Write payload; timestamps are supplied by database defaults and triggers.
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'sex': sex,
    'date_of_birth':
        '${dateOfBirth.year.toString().padLeft(4, '0')}-'
        '${dateOfBirth.month.toString().padLeft(2, '0')}-'
        '${dateOfBirth.day.toString().padLeft(2, '0')}',
    'height_cm': heightCm,
    'weight_kg': weightKg,
    'activity_level': activityLevel,
    'goal': goal,
  };
}
