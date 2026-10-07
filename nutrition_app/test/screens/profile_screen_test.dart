import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/user_profile.dart';
import 'package:nutrition_app/repositories/user_profile_repository.dart';
import 'package:nutrition_app/screens/profile_screen.dart';
import 'package:nutrition_app/screens/profile_edit_screen.dart';

class FakeProfiles implements UserProfileRepository {
  var writes = 0;
  @override
  Future<UserProfile?> getProfile(String id) =>
      throw StateError('Unexpected lookup');
  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    writes++;
    return profile;
  }
}

void main() {
  testWidgets(
    'dashboard shows summaries, email, unavailable deletion and logout',
    (tester) async {
      final repository = FakeProfiles();
      var signOuts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            profile: UserProfile(
              userId: 'user',
              sex: 'female',
              dateOfBirth: DateTime(1990, 2, 3),
              heightCm: 170.3,
              weightKg: 70.5,
              activityLevel: 'lightly_active',
              goal: 'lose',
            ),
            email: 'user@example.com',
            repository: repository,
            onSaved: (_) {},
            onSignOut: () async {
              signOuts++;
            },
          ),
        ),
      );
      expect(find.text('Profilul meu'), findsOneWidget);
      expect(find.text('user@example.com'), findsNWidgets(2));
      expect(find.text('Feminin · 03.02.1990'), findsOneWidget);
      expect(find.text('170,3 cm · 70,5 kg'), findsOneWidget);
      expect(find.text('Ușor activ'), findsOneWidget);
      expect(find.text('Scădere în greutate'), findsOneWidget);
      final delete = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Șterge contul'),
      );
      expect(delete.onTap, isNull);
      expect(delete.enabled, isFalse);
      expect(find.text('Disponibil în curând'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('profileSignOut')));
      await tester.tap(find.byKey(const ValueKey('profileSignOut')));
      await tester.pumpAndSettle();
      expect(signOuts, 1);
      expect(repository.writes, 0);
    },
  );

  testWidgets(
    'section back restores dashboard without saving; logout failure is friendly',
    (tester) async {
      final repository = FakeProfiles();
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            profile: UserProfile(
              userId: 'user',
              sex: 'male',
              dateOfBirth: DateTime(1990),
              heightCm: 180,
              weightKg: 80,
              activityLevel: 'sedentary',
              goal: 'maintain',
            ),
            email: 'user@example.com',
            repository: repository,
            onSaved: (_) {},
            onSignOut: () async => throw Exception('private auth error'),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey(ProfileSection.personal)));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileEditScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Înapoi'));
      await tester.pumpAndSettle();
      expect(find.text('Profilul meu'), findsOneWidget);
      expect(repository.writes, 0);
      await tester.ensureVisible(find.byKey(const ValueKey('profileSignOut')));
      await tester.tap(find.byKey(const ValueKey('profileSignOut')));
      await tester.pumpAndSettle();
      expect(
        find.text('Nu am putut face deconectarea. Încearcă din nou.'),
        findsOneWidget,
      );
      expect(find.textContaining('private auth error'), findsNothing);
    },
  );
}
