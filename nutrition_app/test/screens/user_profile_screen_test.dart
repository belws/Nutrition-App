import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/user_profile.dart';
import 'package:nutrition_app/repositories/user_profile_repository.dart';
import 'package:nutrition_app/screens/user_profile_screen.dart';
import 'package:nutrition_app/widgets/profile_controls.dart';

class FakeProfileRepository implements UserProfileRepository {
  final saves = <UserProfile>[];
  Completer<UserProfile>? pending;

  @override
  Future<UserProfile?> getProfile(String id) =>
      throw StateError('No lookup expected');

  @override
  Future<UserProfile> saveProfile(UserProfile profile) {
    saves.add(profile);
    return pending?.future ?? Future.value(profile);
  }
}

Future<void> tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> back(WidgetTester tester) async {
  await tester.tap(find.text('Înapoi'));
  await tester.pumpAndSettle();
}

Future<DateTime> personalInfo(WidgetTester tester) async {
  await tap(tester, 'female');
  await tap(tester, 'birthDate');
  final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
  final date = picker.initialDate!;
  final now = DateTime.now();
  expect(picker.lastDate, DateTime(now.year, now.month, now.day));
  expect(picker.firstDate, DateTime(1));
  await tester.tap(find.text('Selectează'));
  await tester.pumpAndSettle();
  return date;
}

Future<void> selectWheel(WidgetTester tester, String key, int index) async {
  final picker = tester.widget<CupertinoPicker>(find.byKey(ValueKey(key)));
  picker.scrollController!.jumpToItem(index);
  await tester.pumpAndSettle();
  expect(picker.scrollController!.selectedItem, index);
}

Future<DateTime> reachGoal(WidgetTester tester, {bool custom = false}) async {
  final date = await personalInfo(tester);
  await tap(tester, 'continue');
  expect(find.text('Care este înălțimea ta?'), findsOneWidget);
  expect(
    tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('height')))
        .scrollController!
        .selectedItem,
    55,
  );
  if (custom) {
    await selectWheel(tester, 'height', 60);
  }
  await tap(tester, 'continue');
  expect(find.text('Care este greutatea ta?'), findsOneWidget);
  expect(
    tester
        .widget<CupertinoPicker>(find.byKey(const ValueKey('weight')))
        .scrollController!
        .selectedItem,
    60,
  );
  if (custom) {
    await selectWheel(tester, 'weight', 61);
    expect(find.text('70,5'), findsOneWidget);
  }
  await tap(tester, 'continue');
  expect(
    tester
        .widget<FilledButton>(find.byKey(const ValueKey('continue')))
        .onPressed,
    isNull,
  );
  await tap(tester, 'moderately_active');
  await tap(tester, 'continue');
  expect(find.text('Care este obiectivul tău?'), findsOneWidget);
  expect(
    tester
        .widget<FilledButton>(find.byKey(const ValueKey('saveProfile')))
        .onPressed,
    isNull,
  );
  return date;
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('saveProfile')));
  await tester.pump();
}

void main() {
  late FakeProfileRepository repository;
  late List<UserProfile> completed;
  setUp(() {
    repository = FakeProfileRepository();
    completed = [];
  });

  Future<void> mount(WidgetTester tester, {Future<void> Function()? signOut}) =>
      tester.pumpWidget(
        MaterialApp(
          home: UserProfileScreen(
            userId: 'signed-in-user',
            repository: repository,
            onSaved: completed.add,
            onSignOut: signOut ?? () async {},
          ),
        ),
      );

  testWidgets('initial step requires both sex and birth date', (tester) async {
    await mount(tester);
    expect(find.text('Spune-ne câte ceva despre tine'), findsOneWidget);
    expect(find.text('Masculin'), findsOneWidget);
    expect(find.text('Feminin'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Înapoi'), findsNothing);
    FilledButton next() =>
        tester.widget<FilledButton>(find.byKey(const ValueKey('continue')));
    expect(next().onPressed, isNull);
    await tap(tester, 'female');
    expect(next().onPressed, isNull);
    await tap(tester, 'birthDate');
    await tester.tap(find.text('Anulează'));
    await tester.pumpAndSettle();
    expect(next().onPressed, isNull);
    await personalInfo(tester);
    expect(next().onPressed, isNotNull);
    expect(repository.saves, isEmpty);
  });

  testWidgets('back preserves date, sex and both wheel positions', (
    tester,
  ) async {
    await mount(tester);
    final date = await personalInfo(tester);
    await tap(tester, 'continue');
    await selectWheel(tester, 'height', 60);
    await tap(tester, 'continue');
    await selectWheel(tester, 'weight', 61);
    await back(tester);
    expect(
      tester
          .widget<CupertinoPicker>(find.byKey(const ValueKey('height')))
          .scrollController!
          .selectedItem,
      60,
    );
    await back(tester);
    expect(
      find.text(
        '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year.toString().padLeft(4, '0')}',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<ProfileChoices>(find.byType(ProfileChoices)).value,
      'female',
    );
    await tap(tester, 'continue');
    await tap(tester, 'continue');
    expect(
      tester
          .widget<CupertinoPicker>(find.byKey(const ValueKey('weight')))
          .scrollController!
          .selectedItem,
      61,
    );
    expect(repository.saves, isEmpty);
  });

  testWidgets(
    'only final save sends complete numeric and calendar-date payload',
    (tester) async {
      await mount(tester);
      final date = await reachGoal(tester, custom: true);
      await tap(tester, 'maintain');
      expect(repository.saves, isEmpty);
      await save(tester);
      await tester.pumpAndSettle();
      final profile = repository.saves.single;
      expect(profile.toJson(), {
        'user_id': 'signed-in-user',
        'sex': 'female',
        'date_of_birth':
            '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'height_cm': 180.0,
        'weight_kg': 70.5,
        'activity_level': 'moderately_active',
        'goal': 'maintain',
      });
      expect(profile.heightCm, isA<double>());
      expect(profile.weightKg, isA<double>());
      expect(profile.dateOfBirth, DateTime(date.year, date.month, date.day));
      expect(profile.createdAt, isNull);
      expect(profile.updatedAt, isNull);
      expect(completed.single, same(profile));
    },
  );

  testWidgets('defaults save 175 cm and 70 kg', (tester) async {
    await mount(tester);
    await reachGoal(tester);
    await tap(tester, 'lose');
    await save(tester);
    await tester.pumpAndSettle();
    expect(repository.saves.single.heightCm, 175.0);
    expect(repository.saves.single.weightKg, 70.0);
  });

  for (final activity in [
    'sedentary',
    'lightly_active',
    'moderately_active',
    'very_active',
    'extra_active',
  ]) {
    testWidgets('activity maps exactly to $activity', (tester) async {
      await mount(tester);
      await reachGoal(tester);
      await back(tester);
      await tap(tester, activity);
      await tap(tester, 'continue');
      await tap(tester, 'maintain');
      await save(tester);
      await tester.pumpAndSettle();
      expect(repository.saves.single.activityLevel, activity);
    });
  }

  for (final goal in ['lose', 'maintain', 'gain']) {
    testWidgets('goal maps exactly to $goal', (tester) async {
      await mount(tester);
      await reachGoal(tester);
      await tap(tester, goal);
      await save(tester);
      await tester.pumpAndSettle();
      expect(repository.saves.single.goal, goal);
    });
  }

  testWidgets(
    'pending save prevents duplicates and uses returned stored profile',
    (tester) async {
      repository.pending = Completer<UserProfile>();
      await mount(tester);
      await reachGoal(tester);
      await tap(tester, 'maintain');
      await save(tester);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('saveProfile')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('saveProfile')));
      expect(repository.saves.length, 1);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Înapoi'))
            .onPressed,
        isNull,
      );
      final stored = UserProfile.fromJson({
        ...repository.saves.single.toJson(),
        'created_at': '2026-10-07T10:00:00Z',
        'updated_at': '2026-10-07T10:00:00Z',
      });
      repository.pending!.complete(stored);
      await tester.pumpAndSettle();
      expect(completed.single, same(stored));
    },
  );

  testWidgets(
    'failed save stays on goal and retains every selection for retry',
    (tester) async {
      repository.pending = Completer<UserProfile>();
      await mount(tester);
      await reachGoal(tester, custom: true);
      await tap(tester, 'gain');
      await save(tester);
      repository.pending!.completeError(Exception('private database details'));
      await tester.pumpAndSettle();
      expect(find.text('Care este obiectivul tău?'), findsOneWidget);
      expect(
        find.text('Nu am putut salva profilul. Încearcă din nou.'),
        findsOneWidget,
      );
      expect(find.textContaining('private database details'), findsNothing);
      expect(completed, isEmpty);
      final firstPayload = repository.saves.single.toJson();
      await back(tester);
      await tap(tester, 'continue');
      repository.pending = null;
      await save(tester);
      await tester.pumpAndSettle();
      expect(repository.saves.last.toJson(), firstPayload);
      expect(completed.single.goal, 'gain');
    },
  );

  testWidgets('disposed wizard ignores late save completion', (tester) async {
    repository.pending = Completer<UserProfile>();
    await mount(tester);
    await reachGoal(tester);
    await tap(tester, 'maintain');
    await save(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    repository.pending!.complete(repository.saves.single);
    await tester.pumpAndSettle();
    expect(completed, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-out failure stays friendly', (tester) async {
    await mount(
      tester,
      signOut: () async => throw Exception('private auth error'),
    );
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    expect(
      find.text('Nu am putut face deconectarea. Încearcă din nou.'),
      findsOneWidget,
    );
    expect(find.textContaining('private auth error'), findsNothing);
    expect(repository.saves, isEmpty);
  });
}
