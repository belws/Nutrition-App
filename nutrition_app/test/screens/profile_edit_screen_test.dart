import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/user_profile.dart';
import 'package:nutrition_app/repositories/user_profile_repository.dart';
import 'package:nutrition_app/screens/profile_edit_screen.dart';
import 'package:nutrition_app/widgets/profile_controls.dart';

class FakeProfiles implements UserProfileRepository {
  final writes = <UserProfile>[];
  Completer<UserProfile>? pending;
  @override
  Future<UserProfile?> getProfile(String id) =>
      throw StateError('Unexpected lookup');
  @override
  Future<UserProfile> saveProfile(UserProfile profile) {
    writes.add(profile);
    return pending?.future ?? Future.value(profile);
  }
}

UserProfile original({double height = 180, double weight = 80}) => UserProfile(
  userId: 'user',
  sex: 'male',
  dateOfBirth: DateTime(1990, 2, 3),
  heightCm: height,
  weightKg: weight,
  activityLevel: 'sedentary',
  goal: 'maintain',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 2),
);

void main() {
  late FakeProfiles repository;
  late List<UserProfile> saved;
  var cancellations = 0;
  setUp(() {
    repository = FakeProfiles();
    saved = [];
    cancellations = 0;
  });
  Future<void> mount(
    WidgetTester tester,
    ProfileSection section, {
    UserProfile? profile,
  }) => tester.pumpWidget(
    MaterialApp(
      home: ProfileEditScreen(
        profile: profile ?? original(),
        section: section,
        repository: repository,
        onSaved: saved.add,
        onCancel: () => cancellations++,
      ),
    ),
  );
  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('saveEdits')));
    await tester.pump();
  }

  Future<void> choose(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'personal data preselects values and preserves untouched fields',
    (tester) async {
      await mount(tester, ProfileSection.personal);
      expect(
        tester.widget<ProfileChoices>(find.byType(ProfileChoices)).value,
        'male',
      );
      expect(find.text('03.02.1990'), findsOneWidget);
      await choose(tester, 'female');
      await choose(tester, 'birthDate');
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.initialDate, DateTime(1990, 2, 3));
      await tester.tap(find.text('4').last);
      await tester.tap(find.text('Selectează'));
      await tester.pumpAndSettle();
      await save(tester);
      await tester.pumpAndSettle();
      expect(repository.writes.single.toJson(), {
        ...original().toJson(),
        'sex': 'female',
        'date_of_birth': '1990-02-04',
      });
    },
  );

  testWidgets('measurement wheels preselect and map exact values', (
    tester,
  ) async {
    await mount(tester, ProfileSection.measurements);
    final height = tester.widget<CupertinoPicker>(
      find.byKey(const ValueKey('height')),
    );
    final weight = tester.widget<CupertinoPicker>(
      find.byKey(const ValueKey('weight')),
    );
    expect(height.scrollController!.selectedItem, 60);
    expect(weight.scrollController!.selectedItem, 80);
    height.scrollController!.jumpToItem(61);
    weight.scrollController!.jumpToItem(81);
    await tester.pumpAndSettle();
    await save(tester);
    await tester.pumpAndSettle();
    expect(repository.writes.single.toJson(), {
      ...original().toJson(),
      'height_cm': 181.0,
      'weight_kg': 80.5,
    });
  });

  for (final section in [ProfileSection.activity, ProfileSection.goal]) {
    testWidgets('${section.name} preselects and saves only changed field', (
      tester,
    ) async {
      final profile = original(height: 170.3, weight: 70.2);
      await mount(tester, section, profile: profile);
      final activity = section == ProfileSection.activity;
      expect(
        tester.widget<ProfileChoices>(find.byType(ProfileChoices)).value,
        activity ? 'sedentary' : 'maintain',
      );
      await choose(tester, activity ? 'very_active' : 'gain');
      await save(tester);
      await tester.pumpAndSettle();
      expect(repository.writes.single.toJson(), {
        ...profile.toJson(),
        (activity ? 'activity_level' : 'goal'): activity
            ? 'very_active'
            : 'gain',
      });
    });
  }

  for (final measurements in [(170.3, 70.2), (110.0, 230.75)]) {
    testWidgets(
      'unusual measurements $measurements remain exact until chosen',
      (tester) async {
        final profile = original(
          height: measurements.$1,
          weight: measurements.$2,
        );
        await mount(tester, ProfileSection.measurements, profile: profile);
        expect(find.text(profileNumber(profile.heightCm)), findsOneWidget);
        expect(find.text(profileNumber(profile.weightKg)), findsOneWidget);
        await save(tester);
        await tester.pumpAndSettle();
        expect(repository.writes.single.toJson(), profile.toJson());
        final wheel = tester.widget<CupertinoPicker>(
          find.byKey(const ValueKey('height')),
        );
        // Both test heights precede 175, so the inserted legacy row shifts its index.
        wheel.scrollController!.jumpToItem(56);
        await tester.pumpAndSettle();
        await save(tester);
        await tester.pumpAndSettle();
        expect(repository.writes.last.heightCm, 175);
        expect(repository.writes.last.weightKg, profile.weightKg);
      },
    );
  }

  testWidgets(
    'failure retains draft, blocks duplicates and returns stored row on retry',
    (tester) async {
      repository.pending = Completer<UserProfile>();
      await mount(tester, ProfileSection.goal);
      await choose(tester, 'lose');
      await save(tester);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('saveEdits')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('saveEdits')));
      expect(repository.writes.length, 1);
      repository.pending!.completeError(Exception('private database details'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nu am putut salva profilul. Încearcă din nou.'),
        findsOneWidget,
      );
      expect(find.textContaining('private database'), findsNothing);
      expect(
        tester.widget<ProfileChoices>(find.byType(ProfileChoices)).value,
        'lose',
      );
      expect(saved, isEmpty);
      repository.pending = Completer<UserProfile>();
      await save(tester);
      final stored = UserProfile.fromJson({
        ...repository.writes.last.toJson(),
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-10-07T12:00:00Z',
      });
      repository.pending!.complete(stored);
      await tester.pumpAndSettle();
      expect(saved.single, same(stored));
    },
  );

  testWidgets('cancel performs no write', (tester) async {
    await mount(tester, ProfileSection.goal);
    await choose(tester, 'gain');
    await tester.tap(find.byTooltip('Înapoi'));
    expect(cancellations, 1);
    expect(repository.writes, isEmpty);
  });

  testWidgets('disposed editor ignores pending save', (tester) async {
    repository.pending = Completer<UserProfile>();
    await mount(tester, ProfileSection.goal);
    await save(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    repository.pending!.complete(repository.writes.single);
    await tester.pumpAndSettle();
    expect(saved, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
