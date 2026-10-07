import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/user_profile.dart';
import 'package:nutrition_app/repositories/user_profile_repository.dart';
import 'package:nutrition_app/screens/user_profile_screen.dart';

class FakeProfileRepository implements UserProfileRepository {
  final saves = <UserProfile>[];
  Completer<UserProfile>? pending;
  @override
  Future<UserProfile?> getProfile(String id) async => null;
  @override
  Future<UserProfile> saveProfile(UserProfile profile) {
    saves.add(profile);
    return pending?.future ?? Future.value(profile);
  }
}

Future<void> choose(WidgetTester tester, String key, String label) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<DateTime> fillForm(WidgetTester tester) async {
  await choose(tester, 'sex', 'Feminin');
  await tester.ensureVisible(find.byKey(const ValueKey('birthDate')));
  await tester.tap(find.byKey(const ValueKey('birthDate')));
  await tester.pumpAndSettle();
  final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
  final date = picker.initialDate!;
  final now = DateTime.now();
  expect(picker.lastDate, DateTime(now.year, now.month, now.day));
  await tester.tap(find.text('Selectează'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('height')), '170,5');
  await tester.enterText(find.byKey(const ValueKey('weight')), '65.5');
  await choose(tester, 'activity', 'Moderat activ — activitate regulată');
  await choose(tester, 'goal', 'Menținere');
  return date;
}

Future<void> save(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('saveProfile')));
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

  Future<void> mount(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: UserProfileScreen(
        userId: 'signed-in-user',
        repository: repository,
        onSaved: completed.add,
        onSignOut: () async {},
      ),
    ),
  );

  testWidgets('requires selections, date and positive measurements', (
    tester,
  ) async {
    await mount(tester);
    await save(tester);
    expect(find.text('Alege o opțiune.'), findsNWidgets(3));
    expect(find.text('Alege data nașterii.'), findsOneWidget);
    expect(
      find.text('Introdu o valoare validă mai mare decât 0.'),
      findsNWidgets(2),
    );
    expect(repository.saves, isEmpty);
  });

  testWidgets('rejects invalid, nonpositive and nonfinite numeric input', (
    tester,
  ) async {
    await mount(tester);
    await fillForm(tester);
    for (final invalid in ['abc', '0', '-1', 'NaN', 'Infinity']) {
      await tester.ensureVisible(find.byKey(const ValueKey('height')));
      await tester.enterText(find.byKey(const ValueKey('height')), invalid);
      await tester.enterText(find.byKey(const ValueKey('weight')), invalid);
      await save(tester);
      expect(repository.saves, isEmpty);
      expect(
        find.text('Introdu o valoare validă mai mare decât 0.'),
        findsNWidgets(2),
      );
    }
  });

  testWidgets('maps Romanian choices, date and decimal separators exactly', (
    tester,
  ) async {
    await mount(tester);
    final date = await fillForm(tester);
    await save(tester);
    await tester.pumpAndSettle();
    final profile = repository.saves.single;
    expect(profile.userId, 'signed-in-user');
    expect(profile.sex, 'female');
    expect(profile.activityLevel, 'moderately_active');
    expect(profile.goal, 'maintain');
    expect(profile.heightCm, 170.5);
    expect(profile.weightKg, 65.5);
    expect(profile.dateOfBirth, DateTime(date.year, date.month, date.day));
    expect(
      profile.toJson()['date_of_birth'],
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    );
    expect(
      find.text(
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().padLeft(4, '0')}',
      ),
      findsOneWidget,
    );
    expect(completed.single, same(profile));
  });

  testWidgets('pending save prevents duplicates and returns stored profile', (
    tester,
  ) async {
    repository.pending = Completer<UserProfile>();
    await mount(tester);
    await fillForm(tester);
    await save(tester);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('saveProfile')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('saveProfile')));
    expect(repository.saves.length, 1);
    final stored = UserProfile.fromJson({
      ...repository.saves.single.toJson(),
      'created_at': '2026-10-07T10:00:00Z',
      'updated_at': '2026-10-07T10:00:00Z',
    });
    repository.pending!.complete(stored);
    await tester.pumpAndSettle();
    expect(completed.single, same(stored));
  });

  testWidgets('save failure retains input and shows only friendly error', (
    tester,
  ) async {
    repository.pending = Completer<UserProfile>();
    await mount(tester);
    await fillForm(tester);
    await save(tester);
    repository.pending!.completeError(Exception('private database details'));
    await tester.pumpAndSettle();
    expect(find.byType(UserProfileScreen), findsOneWidget);
    expect(
      find.text('Nu am putut salva profilul. Încearcă din nou.'),
      findsOneWidget,
    );
    expect(find.textContaining('private database details'), findsNothing);
    expect(find.text('170,5'), findsOneWidget);
    expect(find.text('65.5'), findsOneWidget);
    expect(completed, isEmpty);
    repository.pending = null;
    await save(tester);
    await tester.pumpAndSettle();
    expect(completed.single.sex, 'female');
    expect(completed.single.activityLevel, 'moderately_active');
  });

  testWidgets('disposed form ignores a late save result', (tester) async {
    repository.pending = Completer<UserProfile>();
    await mount(tester);
    await fillForm(tester);
    await save(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    repository.pending!.complete(repository.saves.single);
    await tester.pumpAndSettle();
    expect(completed, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
