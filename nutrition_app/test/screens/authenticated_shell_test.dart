import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/food.dart';
import 'package:nutrition_app/models/user_profile.dart';
import 'package:nutrition_app/repositories/food_repository.dart';
import 'package:nutrition_app/repositories/user_profile_repository.dart';
import 'package:nutrition_app/screens/authenticated_shell.dart';
import 'package:nutrition_app/screens/profile_edit_screen.dart';
import 'package:nutrition_app/screens/profile_screen.dart';

class FakeFoods extends FoodRepository {
  var reads = 0;
  @override
  Future<List<Food>> getFoods() async {
    reads++;
    return [];
  }
}

class FakeProfiles implements UserProfileRepository {
  final writes = <UserProfile>[];
  Completer<UserProfile>? pending;
  @override
  Future<UserProfile?> getProfile(String id) =>
      throw StateError('Unexpected lookup');
  @override
  Future<UserProfile> saveProfile(UserProfile profile) {
    writes.add(profile);
    return pending?.future ??
        Future.value(
          UserProfile.fromJson({
            ...profile.toJson(),
            'goal': 'gain',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-10-07T12:00:00Z',
          }),
        );
  }
}

UserProfile profile(String id) => UserProfile(
  userId: id,
  sex: 'male',
  dateOfBirth: DateTime(1990),
  heightCm: 180,
  weightKg: 80,
  activityLevel: 'sedentary',
  goal: 'maintain',
);

void main() {
  testWidgets(
    'tabs preserve catalog and successful edit immediately uses returned profile',
    (tester) async {
      final foods = FakeFoods();
      final profiles = FakeProfiles();
      var signOuts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AuthenticatedShell(
            profile: profile('user'),
            email: 'user@example.com',
            repository: foods,
            profileRepository: profiles,
            onSignOut: () async {
              signOuts++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Catalog alimente'), findsOneWidget);
      expect(foods.reads, 1);
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      final goal = find.byKey(const ValueKey(ProfileSection.goal));
      await tester.ensureVisible(goal);
      await tester.tap(goal);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lose')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('saveEdits')));
      await tester.pumpAndSettle();
      expect(profiles.writes.single.goal, 'lose');
      expect(find.text('Creștere în greutate'), findsOneWidget);
      expect(
        tester
            .widget<ProfileScreen>(find.byType(ProfileScreen))
            .profile
            .updatedAt,
        DateTime.utc(2026, 10, 7, 12),
      );
      await tester.tap(find.text('Catalog'));
      await tester.pumpAndSettle();
      expect(find.text('Catalog alimente'), findsOneWidget);
      expect(foods.reads, 1);
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Creștere în greutate'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('profileSignOut')));
      await tester.tap(find.byKey(const ValueKey('profileSignOut')));
      await tester.pumpAndSettle();
      expect(signOuts, 1);
    },
  );

  testWidgets(
    'user-keyed replacement discards pending editor and saved state',
    (tester) async {
      final foods = FakeFoods();
      final profiles = FakeProfiles()..pending = Completer<UserProfile>();
      Widget app(String id) => MaterialApp(
        home: AuthenticatedShell(
          key: ValueKey(id),
          profile: profile(id),
          email: '$id@example.com',
          repository: foods,
          profileRepository: profiles,
          onSignOut: () async {},
        ),
      );
      await tester.pumpWidget(app('first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      final goal = find.byKey(const ValueKey(ProfileSection.goal));
      await tester.ensureVisible(goal);
      await tester.tap(goal);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('saveEdits')));
      await tester.pump();
      await tester.pumpWidget(app('second'));
      await tester.pumpAndSettle();
      profiles.pending!.complete(profiles.writes.single);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      final screen = tester.widget<ProfileScreen>(find.byType(ProfileScreen));
      expect(screen.profile.userId, 'second');
      expect(screen.email, 'second@example.com');
      expect(find.byType(ProfileEditScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
