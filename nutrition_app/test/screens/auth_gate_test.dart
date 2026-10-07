import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/food.dart';
import 'package:nutrition_app/models/user_profile.dart';
import 'package:nutrition_app/repositories/user_profile_repository.dart';
import 'package:nutrition_app/screens/user_profile_screen.dart';
import 'package:nutrition_app/repositories/food_repository.dart';
import 'package:nutrition_app/screens/auth_gate.dart';
import 'package:nutrition_app/screens/auth_screen.dart';
import 'package:nutrition_app/screens/food_catalog_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeFoodRepository extends FoodRepository {
  @override
  Future<List<Food>> getFoods() async => [];
}

class FakeGoTrueClient extends GoTrueClient {
  FakeGoTrueClient({Session? initialSession})
    : _currentSession = initialSession,
      super(url: 'http://localhost', autoRefreshToken: false);

  Session? _currentSession;
  final _authController = StreamController<AuthState>.broadcast();

  @override
  Session? get currentSession => _currentSession;

  @override
  Stream<AuthState> get onAuthStateChange => _authController.stream;

  void emit(AuthChangeEvent event, Session? session) {
    _currentSession = session;
    _authController.add(AuthState(event, session));
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    emit(AuthChangeEvent.signedOut, null);
  }

  void close() {
    _authController.close();
  }
}

UserProfile profileFor(String id) => UserProfile(
  userId: id,
  sex: 'male',
  dateOfBirth: DateTime(1990, 1, 2),
  heightCm: 180,
  weightKg: 80,
  activityLevel: 'sedentary',
  goal: 'maintain',
);

class FakeProfileRepository implements UserProfileRepository {
  final ids = <String>[];
  final saves = <UserProfile>[];
  Future<UserProfile?> Function(String)? lookup;
  @override
  Future<UserProfile?> getProfile(String id) {
    ids.add(id);
    return lookup == null ? Future.value(profileFor(id)) : lookup!(id);
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    saves.add(profile);
    return profile;
  }
}

Session createSession({String id = '11111111-1111-4111-8111-111111111111'}) {
  final user = User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-10-04T17:00:00Z',
    email: 'test@example.com',
  );

  return Session(
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
    tokenType: 'bearer',
    user: user,
  );
}

void main() {
  late FakeFoodRepository repository;
  late FakeProfileRepository profiles;

  setUp(() {
    repository = FakeFoodRepository();
    profiles = FakeProfileRepository();
  });

  testWidgets(
    'missing profile opens onboarding and saved profile opens catalog without lookup',
    (tester) async {
      profiles.lookup = (_) async => null;
      final auth = FakeGoTrueClient(initialSession: createSession());
      addTearDown(auth.close);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            repository: repository,
            profileRepository: profiles,
            auth: auth,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final screen = tester.widget<UserProfileScreen>(
        find.byType(UserProfileScreen),
      );
      expect(screen.userId, auth.currentSession!.user.id);
      await tester.tap(find.byKey(const ValueKey('male')));
      await tester.tap(find.byKey(const ValueKey('birthDate')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selectează'));
      await tester.pumpAndSettle();
      for (var step = 0; step < 3; step++) {
        await tester.tap(find.byKey(const ValueKey('continue')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('sedentary')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('maintain')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('saveProfile')));
      await tester.tap(find.byKey(const ValueKey('saveProfile')));
      await tester.pumpAndSettle();
      expect(find.byType(FoodCatalogScreen), findsOneWidget);
      expect(profiles.ids, [screen.userId]);
      expect(profiles.saves.single.userId, screen.userId);
    },
  );

  testWidgets('pending lookup shows loading and failure supports retry', (
    tester,
  ) async {
    final pending = Completer<UserProfile?>();
    profiles.lookup = (_) => pending.future;
    final auth = FakeGoTrueClient(initialSession: createSession());
    addTearDown(auth.close);
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          repository: repository,
          profileRepository: profiles,
          auth: auth,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(Exception('private backend error'));
    await tester.pumpAndSettle();
    expect(find.text('Nu am putut încărca profilul.'), findsOneWidget);
    expect(find.byType(UserProfileScreen), findsNothing);
    expect(find.textContaining('private backend error'), findsNothing);
    profiles.lookup = (id) async => profileFor(id);
    await tester.tap(find.text('Încearcă din nou'));
    await tester.pumpAndSettle();
    expect(find.byType(FoodCatalogScreen), findsOneWidget);
    expect(profiles.ids.length, 2);
  });

  testWidgets('rebuild and token refresh do not repeat lookup', (tester) async {
    final auth = FakeGoTrueClient(initialSession: createSession());
    addTearDown(auth.close);
    Widget app() => MaterialApp(
      home: AuthGate(
        repository: repository,
        profileRepository: profiles,
        auth: auth,
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    auth.emit(AuthChangeEvent.tokenRefreshed, createSession());
    await tester.pumpAndSettle();
    expect(profiles.ids.length, 1);
  });

  testWidgets('user changes discard pending lookup and stale save callback', (
    tester,
  ) async {
    final oldLookup = Completer<UserProfile?>();
    final first = createSession();
    profiles.lookup = (id) =>
        id == first.user.id ? oldLookup.future : Future.value(null);
    final auth = FakeGoTrueClient(initialSession: first);
    addTearDown(auth.close);
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          repository: repository,
          profileRepository: profiles,
          auth: auth,
        ),
      ),
    );
    auth.emit(AuthChangeEvent.signedIn, createSession(id: 'second-user'));
    await tester.pumpAndSettle();
    oldLookup.complete(profileFor(first.user.id));
    await tester.pumpAndSettle();
    final oldScreen = tester.widget<UserProfileScreen>(
      find.byType(UserProfileScreen),
    );
    expect(oldScreen.userId, 'second-user');
    auth.emit(AuthChangeEvent.signedIn, createSession(id: 'third-user'));
    await tester.pumpAndSettle();
    oldScreen.onSaved(profileFor('second-user'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<UserProfileScreen>(find.byType(UserProfileScreen)).userId,
      'third-user',
    );
    expect(find.byType(FoodCatalogScreen), findsNothing);
  });

  testWidgets('sign out during lookup ignores its eventual result', (
    tester,
  ) async {
    final pending = Completer<UserProfile?>();
    profiles.lookup = (_) => pending.future;
    final auth = FakeGoTrueClient(initialSession: createSession());
    addTearDown(auth.close);
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          repository: repository,
          profileRepository: profiles,
          auth: auth,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    pending.complete(profileFor('old-user'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(FoodCatalogScreen), findsNothing);
  });

  testWidgets('shows AuthScreen when there is no existing session', (
    tester,
  ) async {
    final auth = FakeGoTrueClient();
    addTearDown(auth.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          repository: repository,
          profileRepository: profiles,
          auth: auth,
        ),
      ),
    );

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(FoodCatalogScreen), findsNothing);
  });

  testWidgets('shows FoodCatalogScreen when a session already exists', (
    tester,
  ) async {
    final auth = FakeGoTrueClient(initialSession: createSession());
    addTearDown(auth.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          repository: repository,
          profileRepository: profiles,
          auth: auth,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(FoodCatalogScreen), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets('reacts to signed-in and signed-out auth changes', (
    tester,
  ) async {
    final auth = FakeGoTrueClient();
    addTearDown(auth.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          repository: repository,
          profileRepository: profiles,
          auth: auth,
        ),
      ),
    );

    expect(find.byType(AuthScreen), findsOneWidget);

    auth.emit(AuthChangeEvent.signedIn, createSession());
    await tester.pumpAndSettle();

    expect(find.byType(FoodCatalogScreen), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);

    auth.emit(AuthChangeEvent.signedOut, null);
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(FoodCatalogScreen), findsNothing);
  });
}
