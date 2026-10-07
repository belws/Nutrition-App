import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/screens/auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeGoTrueClient extends GoTrueClient {
  FakeGoTrueClient() : super(url: 'http://localhost', autoRefreshToken: false);

  String? signInEmail;
  String? signInPassword;
  String? signUpEmail;
  String? signUpPassword;

  final _authController = StreamController<AuthState>.broadcast();

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get onAuthStateChange => _authController.stream;

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    signInEmail = email;
    signInPassword = password;
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    signUpEmail = email;
    signUpPassword = password;
    return AuthResponse();
  }

  void close() {
    _authController.close();
  }
}

void main() {
  late FakeGoTrueClient auth;

  setUp(() {
    auth = FakeGoTrueClient();
  });

  tearDown(() {
    auth.close();
  });

  testWidgets('sign in shows only email and password', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthScreen(auth: auth)));

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Parolă'), findsOneWidget);
    expect(find.text('Confirmă parola'), findsNothing);
  });

  testWidgets('signs in with trimmed email and password', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthScreen(auth: auth)));

    await tester.enterText(
      find.byType(TextField).at(0),
      '  test@example.com  ',
    );
    await tester.enterText(find.byType(TextField).at(1), 'password123');

    await tester.tap(find.widgetWithText(FilledButton, 'Autentificare'));
    await tester.pump();

    expect(auth.signInEmail, 'test@example.com');
    expect(auth.signInPassword, 'password123');
  });

  testWidgets('sign up shows password confirmation field', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthScreen(auth: auth)));

    await tester.tap(find.text('Nu ai cont? Creează unul'));
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Confirmă parola'), findsOneWidget);
  });

  testWidgets('matching passwords call signUp', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthScreen(auth: auth)));

    await tester.tap(find.text('Nu ai cont? Creează unul'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'new@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.enterText(find.byType(TextField).at(2), 'password123');

    await tester.tap(find.widgetWithText(FilledButton, 'Creează cont'));
    await tester.pump();

    expect(auth.signUpEmail, 'new@example.com');
    expect(auth.signUpPassword, 'password123');
    expect(
      find.text('Cont creat. Verifică emailul pentru a confirma contul.'),
      findsOneWidget,
    );
  });

  testWidgets('mismatched passwords do not call signUp', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthScreen(auth: auth)));

    await tester.tap(find.text('Nu ai cont? Creează unul'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'new@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.enterText(find.byType(TextField).at(2), 'different-password');

    await tester.tap(find.widgetWithText(FilledButton, 'Creează cont'));
    await tester.pump();

    expect(auth.signUpEmail, isNull);
    expect(auth.signUpPassword, isNull);
    expect(find.text('Parolele nu coincid.'), findsOneWidget);
  });

  testWidgets('requires email and password before submitting', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AuthScreen(auth: auth)));

    await tester.tap(find.widgetWithText(FilledButton, 'Autentificare'));
    await tester.pump();

    expect(find.text('Introdu adresa de email și parola.'), findsOneWidget);
    expect(auth.signInEmail, isNull);
  });
}
