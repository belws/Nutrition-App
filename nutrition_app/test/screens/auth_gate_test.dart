import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/food.dart';
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

Session createSession() {
  const user = User(
    id: '11111111-1111-4111-8111-111111111111',
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

  setUp(() {
    repository = FakeFoodRepository();
  });

  testWidgets('shows AuthScreen when there is no existing session', (
    tester,
  ) async {
    final auth = FakeGoTrueClient();
    addTearDown(auth.close);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(repository: repository, auth: auth),
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
        home: AuthGate(repository: repository, auth: auth),
      ),
    );

    await tester.pump();

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
        home: AuthGate(repository: repository, auth: auth),
      ),
    );

    expect(find.byType(AuthScreen), findsOneWidget);

    auth.emit(AuthChangeEvent.signedIn, createSession());
    await tester.pump();

    expect(find.byType(FoodCatalogScreen), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);

    auth.emit(AuthChangeEvent.signedOut, null);
    await tester.pump();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(FoodCatalogScreen), findsNothing);
  });
}
